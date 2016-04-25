#!/usr/local/bin/perl
use strict;
use Getopt::Long;
use Data::Dumper;

# 環境変数設定
$ENV{'LANG'}='C';
my $ODIR = $ENV{'PS_ODIR'} || '.';
my $IDIR = $ENV{'PS_IDIR'} || '.';
my $IFILE = $ENV{'PS_IFILE'} || 'tibems_topics.txt';

# 実行オプション解析
my $interval = 5;
GetOptions (
	'--ifile=s' => \$IFILE,	'--idir=s' => \$IDIR, '--odir=s' => \$ODIR);

# ホスト名からシステムを識別
sub ck_sys {
	my ($host) = @_;
	my $cat = 'Etc';
	if ($host=~/(YIA|YIK)/ ) {
		$cat = 'BC';
	} elsif ($host=~/cl/) {
		$cat = 'Cacti';
	} elsif ($host=~/MIE/) {
		$cat = 'EES';
	} elsif ($host=~/YQFDC/) {
		$cat = 'FDC';
	} elsif ($host=~/YQAJ/) {
		$cat = 'SPC';
	} elsif ($host=~/YDW/) {
		$cat = 'YDW';
	} elsif ($host=~/yqmacy/) {
		$cat = 'YMS';
	}
	return $cat;
}

# ファイルオープン
my $infile = "$IDIR/$IFILE";

my %buf = ();
open(IN, $infile) || die "Can't open infile. $!\n";
#2014-05-26 15:22:00.117 YIA5211 On
while (<IN>) {
	$_=~s/(\r|\n)*//g;	# chopの替り
	if ($_=~/^20\d\d-/) {
		my ($date, $time, $host, $status) = split(' ', $_);
		$date=~s/-/\//g;					# 2013-04-23 を 2013/04/23 に変換
		$time=$1 if ($time=~/(.*?)\.\d+/);

		my $tms = "$date $time";
		if ($status eq 'On') {
			my $sys = ck_sys($host);
			$buf{$sys}{$tms} ++;
			$buf{'PowerOn'}{$tms} ++ if ($sys ne 'Etc');
		} else {
			$buf{'PowerOff'}{$tms} ++;
		}
	}
}
close(IN);

# Date       Time     Count
# 2013-04-23 12:00:13 24
mkdir("$ODIR/vm_count");
for my $system(sort keys %buf) {
	my $outfile = "$ODIR/vm_count/vm_count_$system.txt";
	open(OUT, ">$outfile");
	print OUT "Date       Time     Count\n";
	for my $tms(sort keys %{$buf{$system}}) {
		my $ln = sprintf("%s %d\n", $tms, $buf{$system}{$tms});
		print OUT $ln;
	}
	close(OUT);
}

