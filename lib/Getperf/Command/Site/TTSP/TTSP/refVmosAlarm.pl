#!/usr/local/bin/perl
use strict;
use Getopt::Long;
use Data::Dumper;
use File::Basename;
use Log::Log4perl;

# 2014/05/30 13:20:02               Frame Recv (#/sec)    Frame Sent (#/sec)    Frame Dumped (#/sec)
# 2014/05/30 13:20:02 Port ID       Current    Last 5min  Current    Last 5min  Current    Last 5min
# 2014/05/30 13:20:02 --------------------------------------------------------------------------------
# 2014/05/30 13:20:02 hba-a1        589        556        553        502        0         0
# 2014/05/30 13:20:02 hba-a2        0          0          0          0          0         0
# 2014/05/30 13:20:02 hba-b1        6          18         10         23         0         0

# 環境変数設定
$ENV{'LANG'}='C';
my $ODIR = $ENV{'PS_ODIR'} || '.';
my $IDIR = $ENV{'PS_IDIR'} || '.';
my $IFILE = $ENV{'PS_IFILE'} || 'vmos_media.txt';

# 設定ファイルに定義したloggerを生成
my $PWD = `dirname $0`;
chop($PWD);    # ~mon/script
$PWD = File::Spec->rel2abs($PWD);
Log::Log4perl::init("$PWD/log4perl.conf");
my $logger = Log::Log4perl::get_logger("pslog");

# 実行オプション解析
my $interval = 5;
GetOptions (
	'--ifile=s' => \$IFILE,	'--idir=s' => \$IDIR, '--odir=s' => \$ODIR);

# ファイルオープン
my $infile = "$IDIR/$IFILE";

my %buf = ();
open(IN, $infile) || die "Can't open infile. $!\n";
#2014-05-26 15:22:00.117 YIA5211 On
while (<IN>) {
	$_=~s/(\r|\n)*//g;	# chopの替り
	next if ($_!~/^(20\S+ \S+) (.*) (\S+?)$/);
	my ($tms, $body, $stat) = ($1, $2, $3);
	
	if ($stat) {
#		if ($stat!~/^(ok|\(disabled\))/) {
		if ($stat!~/^(ok)/) {
			$logger->info("$tms $body $stat");
		}
	}
	$buf{$tms}{$stat} ++;
}
close(IN);

# Date       Time     ok ng
my $outfile = "$ODIR/$IFILE";
open(OUT, ">$outfile");
print OUT "Date       Time     ok ng\n";
for my $tms(sort keys %buf) {
	my $ok = $buf{$tms}{ok} || 0;
	my $ng = $buf{$tms}{ng} || 0;
	my $cnt = 0;
	map { $cnt += $buf{$tms}{$_}; } keys (%{$buf{$tms}});
	print OUT "$tms $ok $ng\n" if ($cnt == 10);
#	print OUT "$tms $ok $ng\n";
}
close(OUT);

