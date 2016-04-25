#!/usr/local/bin/perl
use strict;
use Getopt::Long;
use Data::Dumper;

# 2014/05/30 13:20:02               Read (bytes/s)      Write (bytes/s)     Read Latency (us)   Write Latency (us)
# 2014/05/30 13:20:02 Media         Current   Last 5m   Current   Last 5m   Current   Last 5m   Current   Last 5m
# 2014/05/30 13:20:02 --------------------------------------------------------------------------------------------
# 2014/05/30 13:20:02 41337F01165   11k       16k       264k      188k      50us    76us      68us      68us

# 環境変数設定
$ENV{'LANG'}='C';
my $ODIR = $ENV{'PS_ODIR'} || '.';
my $IDIR = $ENV{'PS_IDIR'} || '.';
my $IFILE = $ENV{'PS_IFILE'} || 'vmos_media.txt';

# 実行オプション解析
my $interval = 5;
GetOptions (
	'--ifile=s' => \$IFILE,	'--idir=s' => \$IDIR, '--odir=s' => \$ODIR);

my %_norm = ('k', 1, 'm', 1024, 'g', 1048576, 'us', 1, 'ms', 1000, 's', 1000000);
sub norm {
	my ($val) = @_;
	if ($val=~/(\d+)(k|m|g|us|ms|s)/) {
		return $1 * $_norm{$2};
	} else {
		return $val;
	}
}

# ファイルオープン
my $infile = "$IDIR/$IFILE";

my %buf = ();
open(IN, $infile) || die "Can't open infile. $!\n";
#2014-05-26 15:22:00.117 YIA5211 On
while (<IN>) {
	$_=~s/(\r|\n)*//g;	# chopの替り
	next if ($_!~/^(20\S+ \S+) ([0-9|A-F]+?) (.*)$/);
	my ($tms, $media, $body) = ($1, $2, $3);
	my @csvs = split(/\s+/, $body);
	@csvs = map { norm($_); } @csvs;

	$buf{$media} .= $tms . ' ' . join(' ', @csvs) . "\n";	
}
close(IN);

# Date       Time     rd_kb  rd_kbl  wr_kb  wr_kbl  rd_us  rd_usl  wr_us  wr_usl
for my $media(keys %buf) {
	my $outfile = "$ODIR/$IFILE";
	open(OUT, ">$outfile");
	print OUT "Date       Time     rd_kb  rd_kbl  wr_kb  wr_kbl  rd_us  rd_usl  wr_us  wr_usl\n";
	print OUT $buf{$media};
	close(OUT);
}

