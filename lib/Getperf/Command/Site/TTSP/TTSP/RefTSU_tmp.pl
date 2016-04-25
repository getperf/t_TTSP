#!/usr/local/bin/perl

use strict;

# �p�b�P�[�W�Ǎ�
BEGIN { 
  my $pwd = `dirname $0`;
  chop($pwd);
  push( @INC, "$pwd/libs", "$pwd/" );
}

use File::Basename;
use Getopt::Long;
use File::Spec;
use Time::Local qw(timelocal);
use RefAF;

# �O���[�o���ϐ��̐錾�Ə�����
my $DEBUG = 1;
my $READPHASE = 'HEADER';	# �Ǎ��݃t�F�[�Y
my $CURTIME;			# �^�C���X�^���v
my $STARTSEC;			# �J�n����
my $INTERVAL;			# �̎�Ԋu
my %IOSUFFIX = ('read'=>'Rd', 'write'=>'Wr');

# ���s�I�v�V����
$ENV{'LANG'}='C';
my $ODIR = $ENV{'PS_ODIR'} || '.';
my $IDIR = $ENV{'PS_IDIR'} || '.';
my $IFILE = $ENV{'PS_IFILE'} || 'afacs.txt';
my $PARFILE='RefAF_def.pm';

# �p�����[�^�`�F�b�N
GetOptions ('--interval=i' => \$INTERVAL,
	'--ifile=s' => \$IFILE,
	'--idir=s' => \$IDIR,
	'--odir=s' => \$ODIR,
	'--param=s' => \$PARFILE,
) || die "Usage : $0 [--idir=dir] [--ifile=file] [--odir=dir] [--interval=sec] [--param=paramfile]\n";

# �f�o�C�X���
my %TSEC = ();			# �f�o�C�X�ʃ^�C���X�^���v

# �̎�f�[�^
my %WBCDAT = ();		# ���C�g�o�b�N�L���b�V���f�[�^
my %SUMDAT = ();		# �T�}���f�[�^
my %CNTDAT = ();		# �T�}���f�[�^����
my %DEVCNT = ();		# �T�}���f�[�^����(���ԕ�)
my %DETAILDAT = ();		# �ڍ׃f�[�^
my %TRANSDAT = ();		# �]���T�C�Y�f�[�^
my %HOSTTRANSDAT = ();		# �]���T�C�Y�f�[�^
my %HOSTTRANSRATE = ();	# �z�X�gIF�]�����[�g
my %HOSTDAT = ();		# �z�X�gIF�f�[�^
my %TRANSSUMDAT = ();		# �]���T�C�Y�T�}���f�[�^
my %RESPDAT = ();		# ���X�|���X�f�[�^
my %RESPSUMDAT = ();		# ���X�|���X�T�}���f�[�^

# ���X�g�f�[�^
my %DEVLISTALL = ();		# �f�o�C�X���X�g(���ׂ�)
my %HOSTLIST = ();		# �z�X�gIF���X�g
my %CTLLIST = ();		# �R���g���[�����X�g
my %RAIDLIST = ();		# RAID�O���[�v���X�g(�I���̂�)
my %DEVLIST = ();		# �f�o�C�X���X�g(�I���̂�)
my %DATELIST = ();		# �^�C���X�^���v���X�g
my %RESPLIST = ();		# ���X�|���X���X�g
my %BLOCKLIST = ();		# �]���u���b�N���X�g

# ���C�u����RefAF.pm ����Q��
my %AFRESP = %RefAF::AFRESP;	# ���X�|���X���X�g
my %AFBLOCK = %RefAF::AFBLOCK;	# �u���b�N�T�C�Y���X�g

# �p�����[�^�t�@�C���Ǎ�
chop( my $PWD  = `dirname $0` );
$PWD = File::Spec->rel2abs($PWD);
die "Param file Not Found : $PWD/$PARFILE [--param=s]\n" if (!-f "$PWD/$PARFILE");
require "$PWD/$PARFILE";

# �f�o�C�X���X�g�ϊ�
my %AFDEV = %RefAF::AFDEV;	# �f�o�C�X���X�g
for my $devs (keys %AFDEV) {
	my @item = split("\n", $AFDEV{$devs});
	print "Load [$devs]: " . join("|", @item) . "\n" if ($DEBUG);
	for my $dev (@item) {
		$DEVLIST{$dev} = $devs;
	}
}
if ($DEBUG) {
	for my $dev(sort keys %DEVLIST) {
		print "[DEVLIST] $dev => $DEVLIST{$dev}\n";
	}
}

# RAID�O���[�v���X�g�ϊ�
my %AFRAIDG = %RefAF::AFRAIDG;  # RAID�O���[�v���X�g
for my $devs (keys %AFRAIDG) {
	my @item = split("\n", $AFRAIDG{$devs});
	print "Load [$devs]: " . join("|", @item) . "\n" if ($DEBUG);
	for my $dev (@item) {
		my $key = $devs . "_rg" . $dev;
		$RAIDLIST{$key} = $devs;                        # c4t11_rg0
	}
}
if ($DEBUG) {
	for my $dev(sort keys %RAIDLIST) {
		print "[RAIDLIST] $dev => $RAIDLIST{$dev}\n";
	}
}

# ���X�|���X���X�g�ϊ�
for my $resp (keys %AFRESP) {
	my $respsum = $AFRESP{$resp};
	$RESPLIST{$respsum} = 1;
}
if ($DEBUG) {
	my @respgrp;
	for my $resp(sort keys %RESPLIST) {
		push(@respgrp, $resp);
	}
	printf("[RESP] %s\n", join(', ', @respgrp));
}

# �u���b�N�T�C�Y���X�g�ϊ�
for my $block (keys %AFBLOCK) {
	my $blocksum = $AFBLOCK{$block};
	$BLOCKLIST{$blocksum} = 1;
}
if ($DEBUG) {
	my @blockgrp;
	for my $block(sort keys %BLOCKLIST) {
		push(@blockgrp, $block);
	}
	printf("[BLOCK] %s\n", join(', ', @blockgrp));
}

# �z�X�g�ʃu���b�N���[�g���X�g
my @HOSTBLKRATE = ('<__1MB/s', '<__2MB/s', '<__4MB/s', '<__8MB/s', '<_16MB/s',
	'<_32MB/s', '<_64MB/s', '>=64MB/s');

# �L���b�V���p�[�Z���g���z���X�g
my @WBCPCTLIST = (10, 20, 30, 40, 50, 60, 70, 80, 90, 100);

my $row = 0;
my $device;

# ���C��

# �t�@�C�����͐ݒ�
my $PSFILE="$IDIR/$IFILE";
die "$PSFILE not found : $!" if (!-f $PSFILE);
open(IN, $PSFILE) || die "Can't open $PSFILE : $!"; ;

while (<IN>) {
	chop;
print "[$READPHASE,$hostif,$device] $_\n";

	# �w�b�_�[�`�F�b�N
	if (/^=== (.+) ===$/) {
		$row = 0;
		my @item = split(/\s+/, $1);
		$device = shift(@item);
		$device .= '_rg' . $1 if ($_=~/RAID Group:\s+(\d*)\s+HDD/);
		my $head = join(' ', @item);
		# === cXtXX write-back-cache schedule information ===
		if ($head=~/write-back-cache schedule information/) {
			$READPHASE = 'WBCHIST';
		# === cXtXdX access summary information ===
		} elsif ($head=~/access summary information/) {
			$READPHASE = 'SUMMARY';
		# === cXtXX RAID Group: 0 HDD transfer size information ===
		} elsif ($head=~/HDD transfer size information/) {
			$READPHASE = 'HOSTTRANSFER';
		# === cXtXX RAID Group: 0 HDD transfer rate information ===
		} elsif ($head=~/HDD transfer rate information/) {
			$READPHASE = 'HOSTTRANSRATE';
		# === cXtXdX transfer size information ===
		} elsif ($head=~/transfer size information/) {
			$READPHASE = 'TRANSFER';
		# === cXtXdX response time information ===
		} elsif ($head=~/response time information/) {
			$READPHASE = 'RESPONSE';
		# ���̑�
		} else {
			$READPHASE = 'ETC';
		}
	} else {
		$row ++;
	}

	# �w�b�_���ǂݍ���
	if ($READPHASE eq 'HEADER') {
		# �C���^�[�o��
		# interval time	: 30
		if (/interval time\s*:\s*(\d+)/) {
			if ($INTERVAL) {
				print "[HEADER] interval time = $INTERVAL(specified)\n" if ($DEBUG);
			} else {
				$INTERVAL = $1;
				print "[HEADER] interval time = $INTERVAL\n" if ($DEBUG);
			}
		}
		# �J�n����
		# start time	: 2006/07/01 10:27:37
		my $start_time = $_;
		if ($start_time =~ /start time\s+:\s+(\d\d\d\d)\/(\d\d)\/(\d\d) (\d\d):(\d\d):(\d\d)/) {
			my ($year, $month, $day, $hour, $minute, $second) = ($1, $2, $3, $4, $5, $6);
			$STARTSEC = timelocal($second, $minute, $hour, $day, $month-1, $year);
			print "[HEADER] Start time = $year/$month/$day $hour:$minute:$second\n" if ($DEBUG);
		}
	}

	# �R���g���[���L���b�V���q�b�g���ǂݍ��� 
	if ($READPHASE eq 'WBCHIST') {
		# �w�b�_
		if ($row == 0) {
			# �^�C���X�^���v�v�Z
			my $tsec = $TSEC{$device} || $STARTSEC;
			$TSEC{$device} = $tsec + $INTERVAL;
			my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($tsec);
			$CURTIME = sprintf("%04d/%02d/%02d %02d:%02d:%02d", 
				$YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);

			# �^�C���X�^���v���X�g�ɓo�^
			$HOSTLIST{$device} = 1;
			$DATELIST{$CURTIME} = 1;
		# �f�[�^
		} else {
			if ($_=~/^\s+(\d*)% (.*)/) {
				my ($pct, $line) = ($1, $2);

				# ���R�[�h�o�^ key = [�f�o�C�X, �^�C���X�^���v, �p�[�Z���g]
				my @item = split(/\s+/, $line);
				my $cnt = $item[2];

				my $key = join(',', $device, $CURTIME, $pct);
				$WBCDAT{$key} = $cnt;
			}
		}
	}

	# �T�}�����ǂݍ��� 
	if ($READPHASE eq 'SUMMARY') {
		# �w�b�_
		if ($row == 0) {
			# �^�C���X�^���v�v�Z
			my $tsec = $TSEC{$device} || $STARTSEC;
			$TSEC{$device} = $tsec + $INTERVAL;
			my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($tsec);
			$CURTIME = sprintf("%04d/%02d/%02d %02d:%02d:%02d", 
				$YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);

			# �^�C���X�^���v���X�g�ɓo�^
			$DEVLISTALL{$device} = 1;
			$DATELIST{$CURTIME} = 1;
		# �f�[�^
		} else {
			if ($_=~/^(read|write)\s+(.*)/) {
				# ���R�[�h����
				my ($cmd, $line) = ($1, $2);
				$line=~s/\*//g;			# '*'����菜��

				# 1-4��ڂ��擾
				my @item = split(/\s+/, $line);
				for my $iname('kb_s', 'cmd_s', 'rs', 'hdd_s') {
					my $val = shift(@item);

					# ���R�[�h�o�^ key = [�R�}���h, ����, �f�o�C�X, �^�C���X�^���v]
					my $key1 = join(',', ($cmd, $iname, $device, $CURTIME));
					$DETAILDAT{$key1} = $val;
					# ���v�l�o�^ key = [�R�}���h, ����, �f�o�C�X]
					my $key2 = join(',', ($cmd, $iname, $device));
					$SUMDAT{$key2} += $val;
					# �����o�^ key = [�R�}���h, �f�o�C�X]
					my $key3 = join(',', ($cmd, $device));
					$CNTDAT{$key3} ++;
					# �����o�^ key = [�R�}���h, �f�o�C�X, �^�C���X�^���v]
					my $key4 = join(',', $cmd, $device, $CURTIME);
					$DEVCNT{$key4} ++;

					# �R���g���[���ʃf�[�^�o�^
					if (my $ctl=$DEVLIST{$device}) {
						$CTLLIST{$ctl} = 1;

						# ���R�[�h�o�^ key = [�R�}���h, ����, �f�o�C�X, �^�C���X�^���v]
						my $key1 = join(',', ($cmd, $iname, $ctl, $CURTIME));
						$DETAILDAT{$key1} += $val;

						# ���v�l�o�^ key = [�R�}���h, ����, �f�o�C�X]
						my $key2 = join(',', ($cmd, $iname, $ctl));
						$SUMDAT{$key2} += $val;
						# �����o�^ key = [�R�}���h, �f�o�C�X]
						my $key3 = join(',', ($cmd, $ctl));
						$CNTDAT{$key3} ++;
						# �����o�^ key = [�R�}���h, �f�o�C�X, �^�C���X�^���v]
						my $key4 = join(',', $cmd, $ctl, $CURTIME);
						$DEVCNT{$key4} ++;
					}
				}
			}
		}
	}
	
	# �]���T�C�Y���Ǎ���
	if ($READPHASE eq 'TRANSFER') {
		if ($_=~/^([<|>].*B) (.*)/) {
			my ($blk, $line) = ($1, $2);
			$blk = $AFBLOCK{$blk};
			# ���R�[�h�o�^ key = [�R�}���h, �f�o�C�X, �^�C���X�^���v, �u���b�N�T�C�Y]
			my @item = split(/\s+/, $line);
			my $readval = $item[1];
			my $writeval = $item[3];

			if (my $sumdevice = $DEVLIST{$device}) {
				# read �o�^ 
				my $key = join(',', 'read', $device, $CURTIME, $blk);
				$TRANSDAT{$key} = $readval;
				# write �o�^ 
				my $key = join(',', 'write', $device, $CURTIME, $blk);
				$TRANSDAT{$key} = $writeval;

				
				# read �o�^ 
				my $key = join(',', 'read', $sumdevice, $CURTIME, $blk);
				$TRANSSUMDAT{$key} += $readval;
				# write �o�^ 
				my $key = join(',', 'write', $sumdevice, $CURTIME, $blk);
				$TRANSSUMDAT{$key} += $writeval;
			}
		}
	}

	# �z�X�g�ʓ]���T�C�Y���Ǎ���
	if ($READPHASE eq 'HOSTTRANSFER') {
		if ($_=~/^([<|>].*B) (.*)/) {
			my ($blk, $line) = ($1, $2);
			$blk = $AFBLOCK{$blk};
			# ���R�[�h�o�^ key = [�R�}���h, �f�o�C�X, �^�C���X�^���v, �u���b�N�T�C�Y]
			my @item = split(/\s+/, $line);
			my $readval = $item[1];
			my $writeval = $item[3];
			# read �o�^ 
			my $key = join(',', 'read', $device, $CURTIME, $blk);
			$TRANSDAT{$key} = $readval;
			# write �o�^ 
			my $key = join(',', 'write', $device, $CURTIME, $blk);
			$TRANSDAT{$key} = $writeval;
		} elsif ($_=~/^Total\s*(\w+)\s*transfer rate =\s*(.*)KB\/s$/) {
			# ���R�[�h�o�^ key = [�R�}���h, �f�o�C�X, �^�C���X�^���v]
			my ($cmd, $val) = ($1, $2);
			my $key = join(',', $cmd, $device, $CURTIME);
			$HOSTDAT{$key} = $val;
		}
	}

	# �z�X�g�ʓ]�����[�g���Ǎ���
	if ($READPHASE eq 'HOSTTRANSRATE') {
		if ($_=~/^([<|>].*MB\/s) (.*)/) {
			my ($blk, $line) = ($1, $2);
			$blk=~s/\s/_/g;
			# ���R�[�h�o�^ key = [�R�}���h, �f�o�C�X, �^�C���X�^���v, �u���b�N�T�C�Y]
			my @item = split(/\s+/, $line);
			my $readval = $item[1];
			my $writeval = $item[3];
			# read �o�^ 
			my $key = join(',', 'read', $device, $CURTIME, $blk);
			$HOSTTRANSRATE{$key} = $readval;
			# write �o�^ 
			my $key = join(',', 'write', $device, $CURTIME, $blk);
			$HOSTTRANSRATE{$key} = $writeval;
			# read(���v)�o�^
			my $key = join(',', 'rhdd_s', $device, $CURTIME);
			$HOSTDAT{$key} += $readval;
			# write(���v)�o�^
			my $key = join(',', 'whdd_s', $device, $CURTIME);
			$HOSTDAT{$key} += $writeval;
		}
	}

	# ���X�|���X���Ǎ���
	if ($READPHASE eq 'RESPONSE') {
		if ($_=~/^([<|>].*ms) (.*)/) {
			my ($ms, $line) = ($1, $2);
			my $resp = $AFRESP{$ms};
			# ���R�[�h�o�^ key = [�R�}���h, �f�o�C�X, �^�C���X�^���v, ���X�|���X]
			my @item = split(/\s+/, $line);
			my $readval = $item[1];
			my $writeval = $item[3];

			if (my $sumdevice = $DEVLIST{$device}) {
				# read �o�^ 
				my $key = join(',', 'read', $device, $CURTIME, $resp);
				$RESPDAT{$key} = $readval;
				# write �o�^ 
				my $key = join(',', 'write', $device, $CURTIME, $resp);
				$RESPDAT{$key} = $writeval;

				
				# read �o�^ 
				my $key = join(',', 'read', $sumdevice, $CURTIME, $resp);
				$RESPSUMDAT{$key} += $readval;
				# write �o�^ 
				my $key = join(',', 'write', $sumdevice, $CURTIME, $resp);
				$RESPSUMDAT{$key} += $writeval;
			}
		}
	}
}
close(IN);

# ���|�[�g�o��
repsumdat();		# �f�o�C�X�ʃT�}��
repdetdat();		# �f�o�C�X�ʏڍ�
reptransdat();		# �]���T�C�Y
reptransdatsum();	# �]���T�C�Y(�T�}��)
represpdat();		# ���X�|���X
represpdatsum();	# ���X�|���X(�T�}��)
repwbchist();		# ���C�g�L���b�V�����z
rephostdat();		# �z�X�g�ʃT�}��
#rephosttransrate();	# �z�X�g�ʓ]�����[�g

exit();

sub repsumdat {
	open(F, ">$ODIR/RefAFSummary.txt") or die;

	print F "device        rkb/s   rcmd/s      rrs   rhdd/s    wkb/s   wcmd/s      wrs   whdd/s\n";

	for my $device(sort keys %DEVLISTALL) {
		my $line = $device . substr('           ', 0, 10 - length($device));
		for my $cmd('read', 'write') {
			my $key = join(',', $cmd, $device);
			my $cnt = $CNTDAT{$key};
			next if ($cnt == 0);
			for my $item('kb_s', 'cmd_s', 'rs', 'hdd_s') {
				my $key = join(',', $cmd, $item, $device);
				my $val = $SUMDAT{$key} / $cnt;
				$line .= sprintf(" %8.2f", $val);
			}
		}
		print F $line . "\n";
	}
	close(F);
}

sub rephostdat {
	my $head = "date       time     device        rkb/s    wkb/s   rhdd/s   whdd/s\n";
	for my $device(sort keys %RAIDLIST) {
		open(F, ">$ODIR/RefAFRaid_$device.txt") or die;
		print F $head;
		for my $tm(sort keys %DATELIST) {
			my $line = $tm . " ";
			$line .= $device . substr('           ', 0, 10 - length($device));

			my $key = join(',', 'read', $device, $tm);
			my $read = $HOSTDAT{$key};
			my $key = join(',', 'write', $device, $tm);
			my $write = $HOSTDAT{$key};
			my $key = join(',', 'rhdd_s', $device, $tm);
			my $rhdd_s = $HOSTDAT{$key} / $INTERVAL;
			my $key = join(',', 'whdd_s', $device, $tm);
			my $whdd_s = $HOSTDAT{$key} / $INTERVAL;

			$line .= sprintf(" %8.2f %8.2f %8.2f %8.2f", 
				$read, $write, $rhdd_s, $whdd_s);

			print F $line . "\n";
		}
		close(F);
	}
}

sub repdetdat {
	my $head = "date       time     device        rkb/s   rcmd/s      rrs   rhdd/s    wkb/s   wcmd/s      wrs   whdd/s\n";
	for my $device(sort keys %DEVLIST, sort keys %CTLLIST) {
		open(F, ">$ODIR/RefAFDev_$device.txt") or die;
		print F $head;
		for my $tm(sort keys %DATELIST) {
			my $line = $tm . " ";
			$line .= $device . substr('           ', 0, 10 - length($device));
			for my $cmd('read', 'write') {
				my $key = join(',', $cmd, $device, $tm);
				my $cnt = $DEVCNT{$key};
				for my $item('kb_s', 'cmd_s', 'rs', 'hdd_s') {
					my $key = join(',', $cmd, $item, $device, $tm);
					my $unit = 1;
					if ($CTLLIST{$device} && ($item eq 'rs' || $item eq 'hdd_s')) {
						$unit = scalar(split("\n", $AFDEV{$device}));
					}
					my $val = $DETAILDAT{$key} / $unit;
					$line .= sprintf(" %8.2f", $val);
				}
			}
			print F $line . "\n";
		}
		close(F);
	}
}

sub repwbchist {
	my $head = "date       time     device     ";

	for my $item (@WBCPCTLIST) {
		$head .= sprintf(" %8d%", $item);
	}

	for my $device(sort keys %HOSTLIST) {
		my $fname = sprintf("RefAFWBC_%s.txt",$device);
		open(F, ">$ODIR/$fname") or die;
		print F $head . "\n";
		for my $tm(sort keys %DATELIST) {
			my $line = $tm . " ";
			$line .= $device . substr('           ', 0, 10 - length($device)) . " ";
			for my $item (@WBCPCTLIST) {
				my $key = join(',', $device, $tm, $item);
				my $val = $WBCDAT{$key} / $INTERVAL;
				$line .= sprintf(" %9.1f", $val);
			}
			print F $line . "\n";
		}
		close(F);
	}
}

sub reptransdat {
	my $head = "date       time     device     cmd     ";

	for my $item (sort keys %BLOCKLIST) {
		$item=~s/ /_/g;
		$head .= $item . substr('           ', 0, 10 - length($item));
	}

	for my $device(sort keys %DEVLIST, sort keys %RAIDLIST) {
		for my $cmd ('read', 'write') {
			my $fname = sprintf("RefAFSize%s_%s.txt", $IOSUFFIX{$cmd}, $device);
			open(F, ">$ODIR/$fname") or die;
			print F $head . "\n";
			for my $tm(sort keys %DATELIST) {
				my $line = $tm . " ";
				$line .= $device . substr('           ', 0, 10 - length($device)) . " ";
				$line .= $cmd;
				for my $blk(sort keys %BLOCKLIST) {
					my $key = join(',', $cmd, $device, $tm, $blk);
					my $val = $TRANSDAT{$key} / $INTERVAL;
					$line .= sprintf(" %9.1f", $val);
				}
				print F $line . "\n";
			}
			close(F);
		}
	}
}

sub rephosttransrate {
	my $head = "date       time     device     cmd     ";

	for my $item (@HOSTBLKRATE) {
		$head .= $item . substr('           ', 0, 10 - length($item));
	}

	for my $device(sort keys %HOSTLIST) {
		for my $cmd ('read', 'write') {
			my $fname = sprintf("RefAFCtlRate%s_%s.txt", $IOSUFFIX{$cmd}, $device);
			open(F, ">$ODIR/$fname") or die;
			print F $head . "\n";
			for my $tm(sort keys %DATELIST) {
				my $line = $tm . " ";
				$line .= $device . substr('           ', 0, 10 - length($device)) . " ";
				$line .= $cmd;
				for my $blk(@HOSTBLKRATE) {
					my $key = join(',', $cmd, $device, $tm, $blk);
					my $val = $HOSTTRANSRATE{$key} / $INTERVAL;
					$line .= sprintf(" %9.1f", $val);
				}
				print F $line . "\n";
			}
			close(F);
		}
	}
}

sub reptransdatsum {
	my $head = "date       time     device     cmd     ";

	for my $item (sort keys %BLOCKLIST) {
		$head .= $item . substr('           ', 0, 10 - length($item));
	}

	for my $device(sort keys %AFDEV) {
		for my $cmd ('read', 'write') {
			my $fname = sprintf("RefAFSize%s_%s.txt", $IOSUFFIX{$cmd}, $device);
			open(F, ">$ODIR/$fname") or die;
			print F $head . "\n";
			for my $tm(sort keys %DATELIST) {
				my $line = $tm . " ";
				$line .= $device . substr('           ', 0, 10 - length($device)) . " ";
				$line .= $cmd;
				for my $blk(sort keys %BLOCKLIST) {
					my $key = join(',', $cmd, $device, $tm, $blk);
					my $val = $TRANSSUMDAT{$key} / $INTERVAL;
					$line .= sprintf(" %9.1f", $val);
				}
				print F $line . "\n";
			}
			close(F);
		}
	}
}

sub represpdat {
	my $head = "date       time     device     cmd     ";

	for my $item (sort keys %RESPLIST) {
		$head .= $item . substr('           ', 0, 10 - length($item));
	}

	for my $device(sort keys %DEVLIST) {
		for my $cmd ('read', 'write') {
			my $fname = sprintf("RefAFElapse%s_%s.txt", $IOSUFFIX{$cmd}, $device);
			open(F, ">$ODIR/$fname") or die;
			print F $head . "\n";
			for my $tm(sort keys %DATELIST) {
				my $line = $tm . " ";
				$line .= $device . substr('           ', 0, 10 - length($device)) . " ";
				$line .= $cmd;
				for my $resp(sort keys %RESPLIST) {
					my $key = join(',', $cmd, $device, $tm, $resp);

					my $val = $RESPDAT{$key} / $INTERVAL;
					$line .= sprintf(" %9.1f", $val);
				}
				print F $line . "\n";
			}
			close(F);
		}
	}
}

sub represpdatsum {
	my $head = "date       time     device     cmd     ";

	for my $item (sort keys %RESPLIST) {
		$head .= $item . substr('           ', 0, 10 - length($item));
	}

	for my $device(sort keys %AFDEV) {
		for my $cmd ('read', 'write') {
			my $fname = sprintf("RefAFElapse%s_%s.txt", $IOSUFFIX{$cmd}, $device);
			open(F, ">$ODIR/$fname") or die;
			print F $head . "\n";
			for my $tm(sort keys %DATELIST) {
				my $line = $tm . " ";
				$line .= $device . substr('           ', 0, 10 - length($device)) . " ";
				$line .= $cmd;
				for my $resp(sort keys %RESPLIST) {
					my $key = join(',', $cmd, $device, $tm, $resp);

					my $val = $RESPSUMDAT{$key} / $INTERVAL;
					$line .= sprintf(" %9.1f", $val);
				}
				print F $line . "\n";
			}
			close(F);
		}
	}
}