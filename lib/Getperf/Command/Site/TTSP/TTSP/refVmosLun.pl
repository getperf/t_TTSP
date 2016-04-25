#!/usr/local/bin/perl
use strict;
use Getopt::Long;
use Data::Dumper;

#2014/06/05 16:55:01                                 Read      Read      Read  Write     Write     Write
#2014/06/05 16:55:01 LUN                             BW        IOPS      Latency  BW        IOPS      Latency
#2014/06/05 16:55:01                                 (MB/s)              (us)  (MB/s)              (us)
#2014/06/05 16:55:01 ------------------------------------------------------------------------------------------
#2014/06/05 16:55:01 BC01                            0.000     0         0  0.014     2         115
#2014/06/05 16:55:01 BC02                            0.000     0         0  0.000     0         0

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

my (%buf, %latencys_max, %latencys_max_buf, %sum_buf, %system_luns);
open(IN, $infile) || die "Can't open infile. $!\n";
#2014-05-26 15:22:00.117 YIA5211 On
while (<IN>) {
	$_=~s/(\r|\n)*//g;	# chopの替り
	
	# 「2014/06/05 16:55:01 BC01」移行は数値配列として抽出
	next if ($_!~/^(20\S+ \S+)\s+(\S+)\s+((\d|\s|\.)+)$/);
	my ($tms, $lun, $body) = ($1, $2, $3);
	my @csvs = split(/\s+/, $body);

	# システム別LUNの最大値抽出
	my $cat = $lun;
	$cat =~s/\d+$//g;
	my $latency = $csvs[2] + $csvs[5];
	if ($latency >= $latencys_max{$cat}{$tms} || 0) {
		$latencys_max{$cat}{$tms} = $latency;
		$latencys_max_buf{$cat}{$tms} = join(' ', @csvs) . "\n";	
	}

	# システム別LUNの合計値計算
	my $idx = 0;
	$system_luns{$cat}{$lun} = 1;
	for my $csv(@csvs) {
		$sum_buf{$cat}{$tms}[$idx] += $csv;
		$idx ++;
	}

	# LUN別はそのまま登録
	$buf{$lun} .= $tms . ' ' . join(' ', @csvs) . "\n";
}
close(IN);

# システム別最大値出力
# Date       Time     r_mbs r_s r_us w_mbs w_s w_us
for my $cat(keys %latencys_max_buf) {
	my $outfile = "$ODIR/$IFILE";
	$outfile=~s/\.txt/_${cat}_max\.txt/g;
	open(OUT, ">$outfile");
	print OUT "Date       Time     r_mbs r_s r_us w_mbs w_s w_us\n";
	for my $tms(sort keys %{$latencys_max_buf{$cat}}) {
		print OUT $tms . " " . $latencys_max_buf{$cat}{$tms};
	}
	close(OUT);
}

# システム別合計値、平均値出力
for my $cat(keys %sum_buf) {
	my $num_lun = scalar(keys %{$system_luns{$cat}});
	print "$cat:$num_lun\n";

	my $outfile_sum = "$ODIR/$IFILE";
	$outfile_sum=~s/\.txt/_${cat}_sum\.txt/g;
	open(OUT_SUM, ">$outfile_sum");
	print OUT_SUM "Date       Time     r_mbs r_s r_us w_mbs w_s w_us\n";

	my $outfile_ave = "$ODIR/$IFILE";
	$outfile_ave=~s/\.txt/_${cat}_ave\.txt/g;
	open(OUT_AVE, ">$outfile_ave");
	print OUT_AVE "Date       Time     r_mbs r_s r_us w_mbs w_s w_us\n";

	for my $tms(sort keys %{$sum_buf{$cat}}) {
		my $body_sum = join(" ", @{$sum_buf{$cat}{$tms}});
		print OUT_SUM $tms . " " . $body_sum . "\n";
		
		my $body_ave = '';
		for my $csv(@{$sum_buf{$cat}{$tms}}) {
			$body_ave .= ' ' . $csv / $num_lun;
		}
		print OUT_AVE $tms . " " . $body_ave . "\n";
	}
	close(OUT_SUM);
	close(OUT_AVE);
}

# LUN別詳細出力 
mkdir("$ODIR/lun") if (!-d "$ODIR/lun");
for my $lun(keys %buf) {
	my $outfile = "$ODIR/lun/$IFILE";
	$outfile=~s/\.txt/_${lun}\.txt/g;
	open(OUT, ">$outfile");
	print OUT "Date       Time     r_mbs r_s r_us w_mbs w_s w_us\n";
	print OUT $buf{$lun};
	close(OUT);
}

