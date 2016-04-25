#!/usr/local/bin/perl

use strict;

# �ѥå������ɹ�
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

# �����Х��ѿ�������Ƚ����
my $DEBUG = 0;
my $READPHASE = 'HEADER';	# �ɹ��ߥե�����
my $CURTIME;			# �����ॹ�����
my $STARTSEC=0;		# ���ϻ���
my $ENDSEC;	  		# ��λ����
my $INTERVAL;			# �μ�ֳ�
my %IOSUFFIX = ('read'=>'Rd', 'write'=>'Wr');

# �¹ԥ��ץ����
$ENV{'LANG'}='C';
my $ODIR = $ENV{'PS_ODIR'} || '.';
my $IDIR = $ENV{'PS_IDIR'} || '.';
my $IFILE = $ENV{'PS_IFILE'} || 'afacs.txt';
my $PARFILE='RefAF_def.pm';

# �ѥ�᡼�������å�
GetOptions ('--interval=i' => \$INTERVAL,
	'--ifile=s' => \$IFILE,
	'--idir=s' => \$IDIR,
	'--odir=s' => \$ODIR,
	'--param=s' => \$PARFILE,
) || die "Usage : $0 [--idir=dir] [--ifile=file] [--odir=dir] [--interval=sec] [--param=paramfile]\n";

# �ǥХ�������
my %TSEC = ();			# �ǥХ����̥����ॹ�����

# �μ�ǡ���
my %WBCDAT   = ();		# �饤�ȥХå�����å���ǡ���
my %WBCONOFF = ();		# �饤�ȥХå�����å���ON/OFF�ǡ���
my %SUMDAT   = ();		# ���ޥ�ǡ���
my %CNTDAT   = ();		# ���ޥ�ǡ������
my %DEVCNT   = ();		# ���ޥ�ǡ������(������)
my %DETAILDAT = ();		# �ܺ٥ǡ���
my %TRANSDAT = ();		# ž���������ǡ���
my %HOSTTRANSDAT = ();		# ž���������ǡ���
my %HOSTTRANSRATE = ();	# �ۥ���IFž���졼��
my %HOSTDAT = ();		# �ۥ���IF�ǡ���
my %TRANSSUMDAT = ();		# ž�����������ޥ�ǡ���
my %RESPDAT = ();		# �쥹�ݥ󥹥ǡ���
my %RESPSUMDAT = ();		# �쥹�ݥ󥹥��ޥ�ǡ���

# �ꥹ�ȥǡ���
my %DEVLISTALL = ();		# �ǥХ����ꥹ��(���٤�)
my %HOSTLIST = ();		# �ۥ���IF�ꥹ��
my %CTLLIST = ();		# ����ȥ���ꥹ��
my %RAIDLIST = ();		# RAID���롼�ץꥹ��(����Τ�)
my %DEVLIST = ();		# �ǥХ����ꥹ��(����Τ�)
my %DATELIST = ();		# �����ॹ����ץꥹ��
my %RESPLIST = ();		# �쥹�ݥ󥹥ꥹ��
my %BLOCKLIST = ();		# ž���֥�å��ꥹ��

# �饤�֥��RefAF.pm ���黲��
my %AFRESP = %RefAF::AFRESP;	# �쥹�ݥ󥹥ꥹ��
my %AFBLOCK = %RefAF::AFBLOCK;	# �֥�å��������ꥹ��

# �ѥ�᡼���ե������ɹ�
chop( my $PWD  = `dirname $0` );
$PWD = File::Spec->rel2abs($PWD);
die "Param file Not Found : $PWD/$PARFILE [--param=s]\n" if (!-f "$PWD/$PARFILE");
require "$PWD/$PARFILE";

# �إå������ɹ�
my $AFHEAD = ''; 		# $RefAF::AFHEAD;	# �إå�����

# �ǥХ����ꥹ���Ѵ�
my %AFDEV = %RefAF::AFDEV;	# �ǥХ����ꥹ��
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

# RAID���롼�ץꥹ���Ѵ�
my %AFRAIDG = %RefAF::AFRAIDG;  # RAID���롼�ץꥹ��
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

# RAID���롼�ץꥹ���Ѵ�
my %AFSYSID = %RefAF::AFSYSID; 

# �쥹�ݥ󥹥ꥹ���Ѵ�
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

# �֥�å��������ꥹ���Ѵ�
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

# �ۥ����̥֥�å��졼�ȥꥹ��
my @HOSTBLKRATE = ('<__1MB/s', '<__2MB/s', '<__4MB/s', '<__8MB/s', '<_16MB/s',
	'<_32MB/s', '<_64MB/s', '>=64MB/s');

# ����å���ѡ������ʬ�ۥꥹ��
my @WBCPCTLIST = (10, 20, 30, 40, 50, 60, 70, 80, 90, 100);

my $row = 0;
my ($device, $dev_postfix);
my $hostif='etc';

# �ᥤ��

# �ե�������������
my $WBCONOFFDEV;
my $PSFILE="$IDIR/$IFILE";
die "$PSFILE not found : $!" if (!-f $PSFILE);
open(IN, $PSFILE) || die "Can't open $PSFILE : $!"; ;

# �����ॹ�����
my $tsec;

while (<IN>) {
	$_=~s/(\r\n)//g;
	print "[$READPHASE,$hostif,$device] $_\n" if ($DEBUG);

	# �إå��������å�
	if (/^=== (.+) ===$/) {
		$row = 0;
		my $head = $1;

		# ���ֽ��˽��Ϥ����إå������μ襵�����������Ƭ�إå��Ȥ���
		$AFHEAD = $head if ($AFHEAD eq '' && $STARTSEC != 0);
#print "[AFHEAD]$AFHEAD|$head|\n";
#		$hostif = 'etc';

		if ($head eq $AFHEAD) {
			# �����ॹ����׷׻�
			$tsec += $INTERVAL;
			my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($tsec);
			$CURTIME = sprintf("%04d/%02d/%02d %02d:%02d:%02d", 
				$YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);

			# �����ॹ����ץꥹ�Ȥ���Ͽ
#			$DEVLISTALL{$device} = 1;
			$DATELIST{$CURTIME} = 1;
		}
#		$head=~s/c5t/c3t/g;
#		$head=~s/c\dt/c0t/g;
		if ($head=~/(c\d+t\d+)d/) {
			$hostif = $1;
#			print "[system ID] $1:$hostif|\n";
#		} elsif ($head!~/\(0:0\)/) {
#			$hostif = 'etc';
		} elsif ($head=~/^([0-9a-f]{8})[\s\(]/) {
			$hostif = $AFSYSID{$1};
			$hostif = 'etc' if ($hostif eq '');
#			print "[system ID] $1:$hostif|\n";
#		} elsif ($head=~/^(\d.*?)\(/) {
#			$hostif = $AFSYSID{$1};
#			$hostif = 'etc' if ($hostif eq '');
#			print "[system ID] $1:$hostif|\n";
#		}
#		if ($head=~/^:(\d+)/) {
#			$hostif = 'etc';
		}
#print "HEAD=$head,$hostif\n";
#		my @item = split(/\s+/, $hd);
#		$device = shift(@item);
		if ($_=~/RAID Group:\s+(\d*)\s+HDD/) {
			$device = $hostif . '_rg' . $1 ;
		} else {
			$device = $hostif;
		}
		if ($head=~/(c\d*t\d*)([d|:]\d*) /) {
			$device = $1 . $2;
			$dev_postfix = $1;
		}
		if ($head=~/^:(\d+)\s/) {
#			$device = sprintf("%s_%02d", $dev_postfix, $1);
			$device = sprintf("%s-%02d", $hostif, $1);
		}

#		print "[device] $hostif|$device|\n" if ($DEBUG);
#		my $head = join(' ', @item);
		# === cXtXX write-back-cache schedule information ===
		if ($head=~/write-back-cache schedule information/) {
			$READPHASE = 'WBCHIST';
		# === cXtXdX access summary information ===
		} elsif ($head=~/access summary information/) {
			$READPHASE = 'SUMMARY';
		# === 5681ea79(0:0) RAID Group: 0 HDD access information ===
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
		# ����¾
		} else {
			$READPHASE = 'ETC';
		}
	} elsif (/^device\s+LDISK\s+WBC mode/) {
		$row = 0;
		$READPHASE = 'WBCONOFF';
	} elsif (/^controller unit\s+:/) {
		$READPHASE = 'ETC';
	} else {
		$row ++;
	}

	# �إå����ɤ߹���
#	if ($READPHASE eq 'HEADER' or $READPHASE eq 'WBCONOFF') {
#	}
		# ���ϻ���
	if ($READPHASE eq 'WBCONOFF') {
		# ���󥿡��Х�
		# interval time	: 30
		if (/interval time\s*:\s*(\d+)/) {
			if ($INTERVAL) {
				print "[HEADER] interval time = $INTERVAL(specified)\n" if ($DEBUG);
			} else {
				$INTERVAL = $1;
				print "[HEADER] interval time = $INTERVAL\n" if ($DEBUG);
			}
		}
		# start time	: 2006/07/01 10:27:37
		my $start_time = $_;
		if ($start_time =~ /start time\s+:\s+(\d\d\d\d)\/(\d\d)\/(\d\d) (\d\d):(\d\d):(\d\d)/) {
			my ($year, $month, $day, $hour, $minute, $second) = ($1, $2, $3, $4, $5, $6);
			$STARTSEC = timelocal($second, $minute, $hour, $day, $month-1, $year);
			$tsec = $STARTSEC - $INTERVAL;
			$ENDSEC   = $STARTSEC + 300;
			print "[HEADER] Start time = $year/$month/$day $hour:$minute:$second\n" if ($DEBUG);
			print "[HEADER] Start = $STARTSEC, End = $ENDSEC\n" if ($DEBUG);
		}
	}

	# ����ȥ��饭��å���ҥå�Ψ�ɤ߹��� 
	if ($READPHASE eq 'WBCONOFF') {
		# �ǡ���
		my $onoff;
		if ($row > 0) {
			if ($_=~/^(c.*?)d.*(ON|OFF)/ || $_=~/^(---).*(ON|OFF)/) {
				$WBCONOFFDEV = $1 if ($1 ne '---');
				$onoff = $2;
				# �쥳������Ͽ key = [�ǥХ���, ���󥪥�]
				my $key = join(',', $WBCONOFFDEV, $onoff);
				$WBCONOFF{$key} ++;
			}
		}
	}

	# ����ȥ��饭��å���ҥå�Ψ�ɤ߹��� 
	if ($READPHASE eq 'WBCHIST') {
		# �إå�
		if ($row == 0) {
			# �����ॹ����׷׻�
#			my $tsec = $TSEC{$device} || $STARTSEC;
#			$TSEC{$device} = $tsec + $INTERVAL;
#			my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($tsec);
#			$CURTIME = sprintf("%04d/%02d/%02d %02d:%02d:%02d", 
#				$YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);

			# �����ॹ����ץꥹ�Ȥ���Ͽ
			$HOSTLIST{$device} = 1;
#			$DATELIST{$CURTIME} = 1;
		# �ǡ���
		} else {
			if ($_=~/^\s+(\d*)% (.*)/) {
				my ($pct, $line) = ($1, $2);

				# �쥳������Ͽ key = [�ǥХ���, �����ॹ�����, �ѡ������]
				my @item = split(/\s+/, $line);
				my $cnt = $item[2];

				my $key = join(',', $device, $CURTIME, $pct);
				$WBCDAT{$key} += $cnt;
			}
		}
	}

	# ���ޥ����ɤ߹��� 
	if ($READPHASE eq 'SUMMARY') {
		# �إå�
		if ($row == 0) {
			# �����ॹ����׷׻�
#			my $tsec = $TSEC{$device} || $STARTSEC;
#			$TSEC{$device} = $tsec + $INTERVAL;
#			my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($tsec);
#			$CURTIME = sprintf("%04d/%02d/%02d %02d:%02d:%02d", 
#				$YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);

			# �����ॹ����ץꥹ�Ȥ���Ͽ
			$DEVLISTALL{$device} = 1;
#			$DATELIST{$CURTIME} = 1;
		# �ǡ���
		} else {
			if ($_=~/^(read|write)\s+(.*)/) {
				# �쥳����ʬ��
				my ($cmd, $line) = ($1, $2);
				$line=~s/\*//g;			# '*'�������

				# 1-4���ܤ����
				my @item = split(/\s+/, $line);
				for my $iname('kb_s', 'cmd_s', 'rs', 'hdd_s') {
					my $val = shift(@item);

					# �쥳������Ͽ key = [���ޥ��, ����, �ǥХ���, �����ॹ�����]
					my $key1 = join(',', ($cmd, $iname, $device, $CURTIME));
					$DETAILDAT{$key1} += $val;
					# �������Ͽ key = [���ޥ��, ����, �ǥХ���]
					my $key2 = join(',', ($cmd, $iname, $device));
					$SUMDAT{$key2} += $val;
					# �����Ͽ key = [���ޥ��, �ǥХ���]
					my $key3 = join(',', ($cmd, $device));
					$CNTDAT{$key3} ++;
					# �����Ͽ key = [���ޥ��, �ǥХ���, �����ॹ�����]
					my $key4 = join(',', $cmd, $device, $CURTIME);
					$DEVCNT{$key4} ++;

					# ����ȥ����̥ǡ�����Ͽ
					if (my $ctl=$DEVLIST{$device}) {
						$CTLLIST{$ctl} = 1;

						# �쥳������Ͽ key = [���ޥ��, ����, �ǥХ���, �����ॹ�����]
						my $key1 = join(',', ($cmd, $iname, $ctl, $CURTIME));
						$DETAILDAT{$key1} += $val;

						# �������Ͽ key = [���ޥ��, ����, �ǥХ���]
						my $key2 = join(',', ($cmd, $iname, $ctl));
						$SUMDAT{$key2} += $val;
						# �����Ͽ key = [���ޥ��, �ǥХ���]
						my $key3 = join(',', ($cmd, $ctl));
						$CNTDAT{$key3} ++;
						# �����Ͽ key = [���ޥ��, �ǥХ���, �����ॹ�����]
						my $key4 = join(',', $cmd, $ctl, $CURTIME);
						$DEVCNT{$key4} ++;
					}
				}
			}
		}
	}
	
	# ž�����������ɹ���
	if ($READPHASE eq 'TRANSFER') {
		if ($_=~/^([<|>].*B) (.*)/) {
			my ($blk, $line) = ($1, $2);
			$blk = $AFBLOCK{$blk};
			# �쥳������Ͽ key = [���ޥ��, �ǥХ���, �����ॹ�����, �֥�å�������]
			my @item = split(/\s+/, $line);
			my $readval = $item[1];
			my $writeval = $item[3];

			if (my $sumdevice = $DEVLIST{$device}) {
				# read ��Ͽ 
				my $key = join(',', 'read', $device, $CURTIME, $blk);
				$TRANSDAT{$key} += $readval;
				# write ��Ͽ 
				my $key = join(',', 'write', $device, $CURTIME, $blk);
				$TRANSDAT{$key} += $writeval;

				
				# read ��Ͽ 
				my $key = join(',', 'read', $sumdevice, $CURTIME, $blk);
				$TRANSSUMDAT{$key} += $readval;
				# write ��Ͽ 
				my $key = join(',', 'write', $sumdevice, $CURTIME, $blk);
				$TRANSSUMDAT{$key} += $writeval;
			}
		}
	}

	# �ۥ�����ž�����������ɹ���
	if ($READPHASE eq 'HOSTTRANSFER') {
		if ($_=~/^([<|>].*B) (.*)/) {
			my ($blk, $line) = ($1, $2);
			$blk = $AFBLOCK{$blk};
			# �쥳������Ͽ key = [���ޥ��, �ǥХ���, �����ॹ�����, �֥�å�������]
			my @item = split(/\s+/, $line);
			my $readval = $item[1];
			my $writeval = $item[3];
			# read ��Ͽ 
			my $key = join(',', 'read', $device, $CURTIME, $blk);
			$TRANSDAT{$key} += $readval;
			# write ��Ͽ 
			my $key = join(',', 'write', $device, $CURTIME, $blk);
			$TRANSDAT{$key} += $writeval;
		} elsif ($_=~/^Total\s*(\w+)\s*transfer rate =\s*(.*)KB\/s$/) {
			# �쥳������Ͽ key = [���ޥ��, �ǥХ���, �����ॹ�����]
			my ($cmd, $val) = ($1, $2);
			my $key = join(',', $cmd, $device, $CURTIME);
			$HOSTDAT{$key} += $val;
		}
	}

	# �ۥ�����ž���졼�����ɹ���
	if ($READPHASE eq 'HOSTTRANSRATE') {
		if ($_=~/^([<|>].*MB\/s) (.*)/) {
			my ($blk, $line) = ($1, $2);
			$blk=~s/\s/_/g;
			# �쥳������Ͽ key = [���ޥ��, �ǥХ���, �����ॹ�����, �֥�å�������]
			my @item = split(/\s+/, $line);
			my $readval = $item[1];
			my $writeval = $item[3];
			# read ��Ͽ 
			my $key = join(',', 'read', $device, $CURTIME, $blk);
			$HOSTTRANSRATE{$key} += $readval;
			# write ��Ͽ 
			my $key = join(',', 'write', $device, $CURTIME, $blk);
			$HOSTTRANSRATE{$key} += $writeval;
			# read(���)��Ͽ
			my $key = join(',', 'rhdd_s', $device, $CURTIME);
			$HOSTDAT{$key} += $readval;
			# write(���)��Ͽ
			my $key = join(',', 'whdd_s', $device, $CURTIME);
			$HOSTDAT{$key} += $writeval;
		}
	}

	# �쥹�ݥ����ɹ���
	if ($READPHASE eq 'RESPONSE') {
		if ($_=~/^([<|>].*ms) (.*)/) {
			my ($ms, $line) = ($1, $2);
			my $resp = $AFRESP{$ms};
			# �쥳������Ͽ key = [���ޥ��, �ǥХ���, �����ॹ�����, �쥹�ݥ�]
			my @item = split(/\s+/, $line);
			my $readval = $item[1];
			my $writeval = $item[3];

			if (my $sumdevice = $DEVLIST{$device}) {
				# read ��Ͽ 
				my $key = join(',', 'read', $device, $CURTIME, $resp);
				$RESPDAT{$key} += $readval;
				# write ��Ͽ 
				my $key = join(',', 'write', $device, $CURTIME, $resp);
				$RESPDAT{$key} += $writeval;

				
				# read ��Ͽ 
				my $key = join(',', 'read', $sumdevice, $CURTIME, $resp);
				$RESPSUMDAT{$key} += $readval;
				# write ��Ͽ 
				my $key = join(',', 'write', $sumdevice, $CURTIME, $resp);
				$RESPSUMDAT{$key} += $writeval;
			}
		}
	}
}
close(IN);

my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($ENDSEC);
my $ENDTIME = sprintf("%04d/%02d/%02d %02d:%02d:%02d", 
	$YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);
#for my $tm(sort keys %DATELIST) {
#	print "[DATELIST]$tm $ENDTIME\n";
#	if ($tm gt $ENDTIME) {
#		delete $DATELIST{$tm} ;
#	}
#}
if ($DEBUG) {
	for my $tm(sort keys %DATELIST) {
		print "[DATELIST]$tm|$ENDTIME|\n";
	}
}

# ��ݡ��Ƚ���
repsumdat();		# �ǥХ����̥��ޥ�
repdetdat();		# �ǥХ����̾ܺ�
reptransdat();		# ž��������
reptransdatsum();	# ž��������(���ޥ�)
represpdat();		# �쥹�ݥ�
represpdatsum();	# �쥹�ݥ�(���ޥ�)
repwbchist();		# �饤�ȥ���å���ʬ��
repwbconoff();		# �饤�ȥ���å���ʬ��
rephostdat();		# �ۥ����̥��ޥ�
#rephosttransrate();	# �ۥ�����ž���졼��

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

sub repwbconoff {
	my $head = "date       time     device        On      Off";

	for my $device(sort keys %HOSTLIST) {
		my $fname = sprintf("RefAFWBCONOFF_%s.txt",$device);
		open(F, ">$ODIR/$fname") or die;
		print F $head . "\n";
#print "startsec : $STARTSEC\n";
		my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($STARTSEC);
		my $tm = sprintf("%04d/%02d/%02d %02d:%02d:%02d", 
				$YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);
		my $line = $tm . " ";
		$line .= $device . substr('           ', 0, 10 - length($device)) . " ";
		for my $item (('ON', 'OFF')) {
			my $key = join(',', $device, $item);
			my $val = $WBCONOFF{$key};
			$line .= sprintf(" %9d", $val);
		}
		print F $line . "\n";

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
