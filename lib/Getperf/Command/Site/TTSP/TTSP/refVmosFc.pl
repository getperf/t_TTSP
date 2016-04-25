#!/usr/local/bin/perl
use strict;
use Getopt::Long;
use Data::Dumper;

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
	next if ($_!~/^(20\S+ \S+) (hba-\S+?) (.*)$/);
	my ($tms, $port, $body) = ($1, $2, $3);
	my @csvs = split(/\s+/, $body);
	$buf{$port} .= $tms . ' ' . join(' ', @csvs) . "\n";	
}
close(IN);

# Date       Time     recv_c  recv_l  sent_c  sent_l  dumped_c dumped_l
for my $media(keys %buf) {
	my $outfile = "$ODIR/$IFILE";
	$outfile=~s/\.txt/_${media}\.txt/g;
	open(OUT, ">$outfile");
	print OUT "Date       Time     recv_c  recv_l  sent_c  sent_l  dumped_c dumped_l\n";
	print OUT $buf{$media};
	close(OUT);
}

