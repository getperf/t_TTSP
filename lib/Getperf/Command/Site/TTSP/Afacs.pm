package Getperf::Command::Site::TTSP::Afacs;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Site::TTSP::AfacsHeader;
use Getperf::Command::Master::TTSP;

my $DEBUG = 0;
my %controller_headers = get_controller_headers();
my %lun_headers        = get_lun_headers();
my %raid_group_headers = get_raid_group_headers();
my $db = $Getperf::Command::Master::TTSP::db;
# my $db = $Getperf::Command::Master::Linux::db;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 60;

	$data_info->is_remote(1);
	$data_info->step($step);
	my $host = $data_info->host;
	my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}
	my (%controllers, %luns, %raid_groups);
	my (%controller_counts, %lun_counts);
	my $parse_block = '';
	my $controller  = 'Etc';
	my $lun         = 'Etc';
	my $raid_group  = 'Etc';
	my $first_controller = undef;
	my $row = 0;
	open( my $in, $data_info->input_file ) || die "@!";
#	$data_info->skip_header( $in );
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
	    print "[$parse_block,$sec,$controller,$lun] $line\n" if ($DEBUG);
	    if ($line=~/^=== (.+) ===$/) {
	        $row = 0;
	        my $head = $1;
	        # model: AF7500 system ID: 0x26c61ce5 system code: KB3950
	        if ($head =~/model: (.+?) system ID: (.+?) system code: (.+?)$/) {
	        	my ($model, $system_id, $system_code) = ($1, $2, $3);
	        	$controller = $system_id;
	        	$controller =~s/0x//g;
	        	$controllers{$controller}{model}       = $model;
	        	$controllers{$controller}{system_code} = $system_code;
	        	$parse_block = 'INFO';

			# 26c61ce5(0:0) write-back-cache schedule information
	        } elsif ($head =~/^(.+?) write-back-cache schedule information/) {
	        	$controller = $1;
	        	$first_controller = $controller if (!defined($first_controller));
	        	$sec += $step if ($controller eq $first_controller);
	        	$controller=~s/\(.+\)//g;
	        	$parse_block = 'WBC';
			# === c4t20000015B79D90FAd41 access summary information ===
			} elsif ($head =~/^(.+?) access summary information/) {
				$lun = $1;
    			$lun =~s/^.+(d\d+)$/$1/;
	        	$parse_block = 'LUN_SUMMARY';
			# === c4t20000015B79D90FAd41 transfer size information ===
			} elsif ($head =~/^(.+?) transfer size information/) {
				my $label = $1;
				# 5632ea79(0:0) RAID Group: 7 HDD
				if ($label=~/^(.+) RAID Group: (\d+) HDD/) {
					$raid_group = $2;
		        	$parse_block = 'RAID_TRANSFER_SIZE';
				} else {
					$lun = $1;
	    			$lun =~s/^.+(d\d+)$/$1/;
		        	$parse_block = 'LUN_TRANSFER_SIZE';
				}
			# === c4t20000015B79D90FAd41 response time information ===
	        } elsif ($head =~/^(.+?) response time information/) {
				$lun = $1;
    			$lun =~s/^.+(d\d+)$/$1/;
		        $parse_block = ($lun!~/HDD/) ? 'LUN_ELAPSE' : 'HDD_ELAPSE';
			# === c4t20000015B79D90FAd41 distribution count information ===
	        } elsif ($head =~/^(.+?) distribution count information/) {
				$lun = $1;
    			$lun =~s/^.+(d\d+)$/$1/;
	        	$parse_block = 'DISTRIBUTION_COUNT';
			# === 26c61ce5(0:0) RAID Group: 0 HDD access information ===
	        } elsif ($head =~/^(.+?) RAID Group: (\d+?) HDD access information/) {
				$raid_group = $2;
	        	$parse_block = 'RAID_GR_SUMMARY';
	        }
	        # print $head . "\n";
	    }
	    $row ++;

		# [INFO:5] device                                               LDISK   WBC mode    WBC RAIDgr. level   HDD     stripe
		# [INFO:6] c4t20000015B79D90FAd41(c5t20000015B79B90FAd41)       0       resv/rls    ON  0(1)    1       8       256
	    if ($parse_block eq 'INFO' && $row > 1) {
	    	if ($line=~/^(.+?)\s+: (.+?)$/) {
	    		my ($item, $value) = ($1, $2);
	    		$item =~s/\s+/_/g;
	        	$controllers{$controller}{$item} = $value;
	    	} elsif ($line=~/[0-9]$/) {
	    		my @csvs = split(' ', $line);
	    		my $cols = scalar(@csvs);
	    		if ($line!~/time/ && ($cols == 4 || $cols == 8) ) {
		    		@csvs = ('', '', '', '', @csvs) if ($cols == 4);
		    		my ($device, $ldisk, $wbc_mode, $wbc, $raid_gr, $level, $hdd, $stripe) = @csvs;
		    		# Parse device ; c4t20000015B74FEA79d20(c5t20000015B74EEA79d20)
		    		if ($device =~/^(c.+)\(.*\)$/) {
		    			my $device = $1;
		    			$device =~s/^.+(d\d+)$/$1/;
		    			$luns{$controller}{$1} = {ldisk => $ldisk, row => $row};
		    		}
		    		# Parse RaidGr ; 0(1)
		    		if ($raid_gr =~/^(\d+)\(.*\)$/) {
		    			$raid_groups{$controller}{$1} = {level => $level, hdd => $hdd, row => $row};
		    		}
	    			print "INFO($device, $ldisk, $raid_gr, $level, $hdd)\n" if ($DEBUG);
	    		}
	    	}

		# [WBC:2] schedule parameter         schedule count
		# [WBC:3]   10%        500ms            2888 100.0%
	    } elsif ($parse_block eq 'WBC' && $row > 2) {
	    	print "[WBC:$row] $line\n" if ($DEBUG);
    		my ($schedule, $parameter, $count, $pct) = split(' ', $line);
    		$schedule=~s/\%/pct/g;
    		$controllers{$controller}{wbc}{$sec}{$schedule} += $count;

		# [LUN:2] 	 (KB)/s	  cmd/s	 rs(ms)	 HDD /s	      cmd   hit	      blk   hit	    que
		# [LUN:3] read	    0.0    13.5	    0.0	   97.6	      866   0.0	      876   0.0	    1.1
		# [LUN:4] write	    0.0    36.6	    0.0	  101.2	     2340 100.0	     2340 100.0	
	    } elsif ($parse_block eq 'LUN_SUMMARY' && $row > 2) {
	    	if (exists($luns{$controller}{$lun}{ldisk})) {
	    		# my ($mode, $kb_s, $cmd_s, $rs, $hdd_s) = split(' ', $line);
	    		my @csvs = split(' ', $line);
	    		my $mode = shift(@csvs);
	    		$mode = ($mode eq 'read') ? 'r' : 'w';
	    		my $cols = 0;
	    		for my $item(qw/kb_s cmd_s rs hdd_s/) {
	    			my $item2 = $mode . $item;
	    			my $value = $csvs[$cols];
	    			$value =~s/\*//g;
	    			if ($item eq 'rs') {
			    		if (!defined($controllers{$controller}{summary}{$sec}{$item2}) || 
			    			$controllers{$controller}{summary}{$sec}{$item2} > 0) {
			    			$controllers{$controller}{summary}{$sec}{$item2} += $value;
			    			$controller_counts{$controller}{summary}{$sec}{$item2} ++;
			    		}
			    		if (!defined($luns{$controller}{$lun}{lun_summary}{$sec}{$item2}) || 
			    			$luns{$controller}{$lun}{lun_summary}{$sec}{$item2} > 0) {
			    			$luns{$controller}{$lun}{lun_summary}{$sec}{$item2} += $value;
			    			$lun_counts{$controller}{$lun}{lun_summary}{$sec}{$item2} ++;
			    		}
    				} else {
			    		$controllers{$controller}{summary}{$sec}{$item2}    += $value;
			    		$luns{$controller}{$lun}{lun_summary}{$sec}{$item2} += $value;
    				}
	    			$cols ++;
	    		}
	    		$controllers{$controller}{summary}{$sec}{count} ++;
		    	print "[LUN_SUMMARY:$row:$controller:$lun] $line\n" if ($DEBUG);
	    	}

		# [SIZE:2]                read             write        read-ahead write-back
		# [SIZE:3] <=   2KB         65   3.8%          0   0.0%          0       0
	    } elsif ($parse_block eq 'LUN_TRANSFER_SIZE' && $row > 2) {
	    	print "[LUN_TRANSFER_SIZE:$row] $line\n" if ($DEBUG);
	    	if (exists($luns{$controller}{$lun}{ldisk})) {
	    		my ($mode, $block, $read, $read_pct, $write, $write_pct) = split(' ', $line);
	    		if ($block =~ /B$/) {
		    		$mode = ($mode eq '>') ? 'ge_' : 'lt_';
		    		my $item = $mode . $block;
		    		$controllers{$controller}{read_size}{$sec}{$item}     += $read;
		    		$luns{$controller}{$lun}{lun_read_size}{$sec}{$item}  += $read;
		    		$controllers{$controller}{write_size}{$sec}{$item}    += $write;
		    		$luns{$controller}{$lun}{lun_write_size}{$sec}{$item} += $write;

	    		}
	    	}

		# [SIZE:2]               read             write
		# [SIZE:3] <   1KB          0   0.0%          0   0.0%
	    } elsif ($parse_block eq 'RAID_TRANSFER_SIZE' && $row > 1) {
	    	print "[SIZE:$row] $line\n" if ($DEBUG);
    		my ($mode, $block, $read, $read_pct, $write, $write_pct) = split(' ', $line);
    		if ($block =~ /B$/) {
	    		$mode = ($mode eq '>=') ? 'ge_' : 'lt_';
	    		my $item = $mode . $block;
	    		$raid_groups{$controller}{$raid_group}{raid_read_size}{$sec}{$item}  = $read;
	    		$raid_groups{$controller}{$raid_group}{raid_write_size}{$sec}{$item} = $write;
    		}

		# [LUN_ELAPSE:2]               read             write        read-ahead write-back
		# [LUN_ELAPSE:3] < 0.1ms         48   2.8%          0   0.0%          0          0
	    } elsif ($parse_block eq 'LUN_ELAPSE' && $row > 2) {
	    	if (exists($luns{$controller}{$lun}{ldisk})) {
		    	print "[LUN_ELAPSE:$row] $line\n" if ($DEBUG);
	    		my ($mode, $elapse, $read, $read_pct, $write, $write_pct) = split(/[ =]+/, $line);
	    		if ($elapse =~ /s$/) {
	    			$elapse=~s/\./_/g;
		    		$mode = ($mode eq '>') ? 'ge_' : 'lt_';
		    		my $item = $mode . $elapse;
		    		$controllers{$controller}{read_elapse}{$sec}{$item}     += $read;
		    		$luns{$controller}{$lun}{lun_read_elapse}{$sec}{$item}  += $read;
		    		$controllers{$controller}{write_elapse}{$sec}{$item}    += $write;
		    		$luns{$controller}{$lun}{lun_write_elapse}{$sec}{$item} += $write;
	    		}
	    	}

		# [RAID:2] HDD No       read      write  read total response  write total response
		# [RAID:3]      0       11.0       10.1                35.50                 32.65
	    } elsif ($parse_block eq 'RAID_GR_SUMMARY' && $row > 2) {
	    	print "[RAID:$row] $line\n" if ($DEBUG);
    		my @csvs = split(' ', $line);
    		my $hdd = shift(@csvs);
    		my $ncol = scalar(@csvs);
    		if ($ncol == 2 || $ncol == 4) {
	    		my $cols = 0;
	    		for my $item(qw/rcmd_s wcmd_s rrs wrs/) {
	    			my $value = $csvs[$cols] || 0;
		    		$raid_groups{$controller}{$raid_group}{raid_summary}{$sec}{$item} += $value;
	    			$cols ++;
	    		}

    		}
	    }
	}
	close($in);
	for my $controller(keys %controllers) {
		for my $sec(keys %{$controllers{$controller}{summary}}) {
			for my $item(qw/rrs wrs/) {
				my $count = $controller_counts{$controller}{summary}{$sec}{$item};
				if ($count == 0) {
					$controllers{$controller}{summary}{$sec}{$item} = 0;
				} else {
					$controllers{$controller}{summary}{$sec}{$item} /= $count;
				}
			}
		}
		for my $lun(sort keys %{$luns{$controller}}) {
			$luns{$controller}{$lun}{row} = 9999 if (!defined($luns{$controller}{$lun}{row}));
			for my $sec(keys %{$luns{$controller}{$lun}{lun_summary}}) {
				for my $item(qw/rrs wrs/) {
					my $count = $lun_counts{$controller}{$lun}{lun_summary}{$sec}{$item};
					if ($count == 0) {
						$luns{$controller}{$lun}{lun_summary}{$sec}{$item} = 0;
					} else {
						$luns{$controller}{$lun}{lun_summary}{$sec}{$item} /= $count;
					}
				}
			}
		}
		for my $raid_group(sort keys %{$raid_groups{$controller}}) {
			if (!defined($raid_groups{$controller}{$raid_group}{row})) {
				$raid_groups{$controller}{$raid_group}{row} = 9999;
			}
			for my $sec(keys %{$raid_groups{$controller}{$raid_group}{raid_summary}}) {
				my $rcmd_s = $raid_groups{$controller}{$raid_group}{raid_summary}{$sec}{rcmd_s};
				if ($rcmd_s > 0) {
					$raid_groups{$controller}{$raid_group}{raid_summary}{$sec}{rrs} /= $rcmd_s;
				}
				my $wcmd_s = $raid_groups{$controller}{$raid_group}{raid_summary}{$sec}{wcmd_s};
				if ($wcmd_s > 0) {
					$raid_groups{$controller}{$raid_group}{raid_summary}{$sec}{wrs} /= $wcmd_s;
				}
			}
		}
	}

	for my $controller(sort keys %controllers) {
		my $host = $controllers{$controller}{system_code};
		my %infos = ();
		if (exists($db->{controllers}{$host})) {
			$infos{application} = $db->{controllers}{$host};
		}
		for my $item(qw/controller_unit host_interface cache_size FW_revision/) {
			if (exists($controllers{$controller}{$item})) {
				$infos{$item} = $controllers{$controller}{$item};
			} else {
				$infos{$item} = $item;
			}
		}
		$data_info->regist_node($host, 'ArrayFort', 'info/model', \%infos);

		for my $metric(qw/wbc summary read_elapse write_elapse read_size write_size/) {
			$data_info->regist_metric($host, 'ArrayFort', $metric, $controller_headers{$metric});
			my $output_file = "ArrayFort/${host}/${metric}.txt";
			$data_info->pivot_report($output_file, $controllers{$controller}{$metric}, 
				                     $controller_headers{$metric});
		}
		for my $lun(sort {$luns{$controller}{$a}{row} <=> $luns{$controller}{$b}{row}}
			        keys %{$luns{$controller}}) {
			if (exists($luns{$controller}{$lun}{ldisk})) {
				my $lun_text = '';
				if (exists($db->{luns}{$host}{$lun})) {
					$lun_text = $lun . ' - ' . $db->{luns}{$host}{$lun};
				}
				my $lun2 = alias_lun($host, $lun, $lun_text);
				next if (!$lun2);
				for my $device_metric(qw/lun_summary lun_read_elapse lun_write_elapse lun_read_size lun_write_size/) {
					$data_info->regist_device($host, 'ArrayFort', $device_metric, $lun2, $lun_text, 
											  $lun_headers{$device_metric});
					my $output_file = "ArrayFort/${host}/device/${device_metric}__${lun2}.txt";
					$data_info->pivot_report($output_file, $luns{$controller}{$lun}{$device_metric}, 
						                     $lun_headers{$device_metric});
				}
			}
		}
		for my $raid_group(sort {$raid_groups{$controller}{$a}{row} <=> $raid_groups{$controller}{$b}{row}}
			               keys %{$raid_groups{$controller}}) {
			my $raid_group_text = '';
			if (exists($db->{raid_groups}{$host}{$raid_group})) {
				$raid_group_text = $db->{raid_groups}{$host}{$raid_group};
			}
			my $raid_group2 = alias_raid_group($host, $raid_group, $raid_group_text);
			next if (!$raid_group2);
			for my $device_metric(qw/raid_summary raid_read_size raid_write_size/) {
				$data_info->regist_device($host, 'ArrayFort', $device_metric, $raid_group2, $raid_group_text, 
										  $raid_group_headers{$device_metric});
				my $output_file = "ArrayFort/${host}/device/${device_metric}__${raid_group2}.txt";
				$data_info->pivot_report($output_file, $raid_groups{$controller}{$raid_group}{$device_metric}, 
					                     $raid_group_headers{$device_metric});
			}
		}
	}
	return 1;
}

1;
