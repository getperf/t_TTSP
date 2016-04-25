package Getperf::Command::Site::Storage::Master;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw/get_controllers get_raid_groups get_devices get_response_hist get_blocksize_hist /;
our @EXPORT_OK = qw/get_controllers get_raid_groups get_devices get_response_hist get_blocksize_hist/;

# ---------- Array Fort コントローラリスト ---------- 
sub get_controllers {
	(
		'458d51df' => 'SC3000-1',
	);
}

# ---------- Array Fort RAIDグループリスト ---------- 
sub get_raid_groups {
	(
		'SC3000-1' => join( "\n",
			0,
			1,
			2,
			3,
			4,
		),
	);
}

# ---------- Array Fort デバイスリスト ---------- 
sub get_devices {
	(
		'SC3000-1' => join("\n",
			'SC3000-1-00',
	        'SC3000-1-00',
	        'SC3000-1-01',
	        'SC3000-1-02',
	        'SC3000-1-03',
	        'SC3000-1-04',
	        'SC3000-1-05',
	        'SC3000-1-06',
	        'SC3000-1-07',
	        'SC3000-1-08',
	        'SC3000-1-09',
	        'SC3000-1-10',
	        'SC3000-1-11',
	        'SC3000-1-12',
	        'SC3000-1-13',
	        'SC3000-1-14',
	        'SC3000-1-15',
		),
	);
}

sub get_response_hist {
	(
		'< 0.1ms'=>'<000.2ms',
		'< 0.2ms'=>'<000.2ms',
		'< 0.3ms'=>'<000.5ms',
		'< 0.4ms'=>'<000.5ms',
		'< 0.5ms'=>'<000.5ms',
		'< 0.6ms'=>'<001.0ms',
		'< 0.7ms'=>'<001.0ms',
		'< 0.8ms'=>'<001.0ms',
		'< 0.9ms'=>'<001.0ms',
		'<   1ms'=>'<001.0ms',
		'<   2ms'=>'<003.0ms',
		'<   3ms'=>'<003.0ms',
		'<   4ms'=>'<005.0ms',
		'<   5ms'=>'<005.0ms',
		'<   6ms'=>'<010.0ms',
		'<   7ms'=>'<010.0ms',
		'<   8ms'=>'<010.0ms',
		'<   9ms'=>'<010.0ms',
		'<  10ms'=>'<010.0ms',
		'<  20ms'=>'<020.0ms',
		'<  30ms'=>'<050.0ms',
		'<  40ms'=>'<050.0ms',
		'<  50ms'=>'<050.0ms',
		'<  60ms'=>'<100.0ms',
		'<  70ms'=>'<100.0ms',
		'<  80ms'=>'<100.0ms',
		'<  90ms'=>'<100.0ms',
		'< 100ms'=>'<100.0ms',
		'>=100ms'=>'>100.0ms',
	);
}

sub get_blocksize_hist {
	(
		'<   1KB'=>'<    2KB',
		'<   2KB'=>'<    2KB',
		'<   4KB'=>'<    8KB',
		'<   8KB'=>'<    8KB',
		'<  16KB'=>'<   16KB',
		'<  32KB'=>'<   32KB',
		'<  64KB'=>'<   64KB',
		'< 128KB'=>'<  128KB',
		'< 256KB'=>'<  256KB',
		'< 512KB'=>'<  512KB',
		'<   1MB'=>'< 1024KB',
		'<   2MB'=>'>=1024KB',
		'<   4MB'=>'>=1024KB',
		'>=  4MB'=>'>=1024KB',
		'<=   2KB'=>'<    2KB',
		'<=   8KB'=>'<    8KB',
		'<=  16KB'=>'<   16KB',
		'<=  32KB'=>'<   32KB',
		'<=  64KB'=>'<   64KB',
		'<= 128KB'=>'<  128KB',
		'<= 256KB'=>'<  256KB',
		'<= 512KB'=>'<  512KB',
		'<=   1MB'=>'< 1024KB',
		'>    1MB'=>'>=1024KB',
	);
}

1;
