package Getperf::Command::Site::TTSP::AfacsHeader;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw/get_controller_headers get_lun_headers get_raid_group_headers/;
our @EXPORT_OK = qw/get_controller_headers get_lun_headers get_raid_group_headers/;

sub get_controller_headers {
	(
		'wbc' => [ qw(
            10pct
            20pct
            30pct
            40pct
            50pct
            60pct
            70pct
            80pct
            90pct
            100pct
		)],
		'summary' => [ qw(
            rcmd_s
            wcmd_s
            rkb_s
            wkb_s
            rhdd_s
            whdd_s
            rrs
            wrs
		)],
		'read_elapse' => [ qw(
            lt_0_1ms
            lt_0_2ms
            lt_0_3ms
            lt_0_4ms
            lt_0_5ms
            lt_0_6ms
            lt_0_7ms
            lt_0_8ms
            lt_0_9ms
            lt_1ms
            lt_2ms
            lt_3ms
            lt_4ms
            lt_5ms
            lt_6ms
            lt_7ms
            lt_8ms
            lt_9ms
            lt_10ms
            lt_20ms
            lt_30ms
            lt_40ms
            lt_50ms
            lt_60ms
            lt_70ms
            lt_80ms
            lt_90ms
            lt_100ms
            ge_100ms
        )],
		'write_elapse' => [ qw(
            lt_0_1ms
            lt_0_2ms
            lt_0_3ms
            lt_0_4ms
            lt_0_5ms
            lt_0_6ms
            lt_0_7ms
            lt_0_8ms
            lt_0_9ms
            lt_1ms
            lt_2ms
            lt_3ms
            lt_4ms
            lt_5ms
            lt_6ms
            lt_7ms
            lt_8ms
            lt_9ms
            lt_10ms
            lt_20ms
            lt_30ms
            lt_40ms
            lt_50ms
            lt_60ms
            lt_70ms
            lt_80ms
            lt_90ms
            lt_100ms
            ge_100ms
        )],
		'read_size' => [ qw(
            lt_2KB
            lt_8KB
            lt_16KB
            lt_32KB
            lt_64KB
            lt_128KB
            lt_256KB
            lt_512KB
            lt_1MB
            ge_1MB
		)],
		'write_size' => [ qw(
            lt_2KB
            lt_8KB
            lt_16KB
            lt_32KB
            lt_64KB
            lt_128KB
            lt_256KB
            lt_512KB
            lt_1MB
            ge_1MB
		)],
	);
}

sub get_lun_headers {
	(
		'lun_summary' => [ qw(
            rcmd_s
            wcmd_s
            rkb_s
            wkb_s
            rhdd_s
            whdd_s
            rrs
            wrs
		)],
		'lun_read_elapse' => [ qw(
            lt_0_1ms
            lt_0_2ms
            lt_0_3ms
            lt_0_4ms
            lt_0_5ms
            lt_0_6ms
            lt_0_7ms
            lt_0_8ms
            lt_0_9ms
            lt_1ms
            lt_2ms
            lt_3ms
            lt_4ms
            lt_5ms
            lt_6ms
            lt_7ms
            lt_8ms
            lt_9ms
            lt_10ms
            lt_20ms
            lt_30ms
            lt_40ms
            lt_50ms
            lt_60ms
            lt_70ms
            lt_80ms
            lt_90ms
            lt_100ms
            ge_100ms
        )],
		'lun_write_elapse' => [ qw(
            lt_0_1ms
            lt_0_2ms
            lt_0_3ms
            lt_0_4ms
            lt_0_5ms
            lt_0_6ms
            lt_0_7ms
            lt_0_8ms
            lt_0_9ms
            lt_1ms
            lt_2ms
            lt_3ms
            lt_4ms
            lt_5ms
            lt_6ms
            lt_7ms
            lt_8ms
            lt_9ms
            lt_10ms
            lt_20ms
            lt_30ms
            lt_40ms
            lt_50ms
            lt_60ms
            lt_70ms
            lt_80ms
            lt_90ms
            lt_100ms
            ge_100ms
        )],
		'lun_read_size' => [ qw(
            lt_2KB
            lt_8KB
            lt_16KB
            lt_32KB
            lt_64KB
            lt_128KB
            lt_256KB
            lt_512KB
            lt_1MB
            ge_1MB
		)],
		'lun_write_size' => [ qw(
            lt_2KB
            lt_8KB
            lt_16KB
            lt_32KB
            lt_64KB
            lt_128KB
            lt_256KB
            lt_512KB
            lt_1MB
            ge_1MB
		)],
	);
}

sub get_raid_group_headers {
	(
		'raid_summary' => [ qw(
			rcmd_s
			wcmd_s
			rrs
			wrs
		)],
		'raid_read_size' => [ qw(
           lt_1KB
           lt_4KB
           lt_8KB
           lt_32KB
           lt_64KB
           lt_256KB
           lt_512KB
           lt_1MB
           lt_2MB
           lt_4MB
           ge_4MB
		)],
		'raid_write_size' => [ qw(
           lt_1KB
           lt_4KB
           lt_8KB
           lt_32KB
           lt_64KB
           lt_256KB
           lt_512KB
           lt_1MB
           lt_2MB
           lt_4MB
           ge_4MB
		)],
	);
}

1;
