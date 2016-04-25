package Getperf::Command::Master::TTSP;
use strict;
use warnings;
use Exporter 'import';
use Data::Dumper;

our @EXPORT = qw/alias_lun alias_raid_group/;

our $db = {
	_node_dir   => {
		'KB3950' => 'Y4',
		'KB2801' => 'Y4',
		'KB3266' => 'Y4',
		'KB2800' => 'Y4',
		'KB3024' => 'Y4',
		'KB2802' => 'Y4',
		'KB4382' => 'Y4',

		'KB4611' => 'Y5',
		'KB4612' => 'Y5',
		'KB4613' => 'Y5',
		'KB4614' => 'Y5',
		'KB4615' => 'Y5',

	},
	controllers => {
		# === model: AF7500 system ID: 0x26c61ce5 system code: KB3950 ===
		'KB3950' => 'Y4 S-URA - c3t18',
		# === model: AF7000 system ID: 0x5632ea79 system code: KB2801 ===
		'KB2801' => 'Y4 URA,RTD,STAR #1 - c3t11',
		# === model: AF7000 system ID: 0x82e1ed79 system code: KB3266 ===
		'KB3266' => 'Y4 URA,RTD,STAR #2 - c3t16',
		# === model: AF7000 system ID: 0x5681ea79 system code: KB2800 ===
		'KB2800' => 'Y4 URA,RTD,STAR #3 - c3t10',
		# === model: AF7000 system ID: 0x410fea79 system code: KB3024 ===
		'KB3024' => 'Y4 URA,RTD,STAR #4 - c3t13',
		# === model: AF7000 system ID: 0x5495ea79 system code: KB2802 ===
		'KB2802' => 'Y4 URA,RTD,STAR #5 - c3t12',
		# === model: AF2500 system ID: 0x234e438c system code: KB4382 ===
		'KB4382' => 'Y4 URA,RTD,STAR #6 - c3t14',
	},
	luns        => {
		'KB2800' => {
		    'd0'  => '/ura/dat1',
		    'd11' => '/rtd/dat2',
		    'd30' => '/yokmst/dat',
		    'd40' => '/superura/dat',
		    'd14' => '/rtd/redo',
		},
		'KB2801' => {
		    'd1'  => '/ura/dat2',
		    'd10' => '/rtd/dat1',
		    'd44' => '/superura/redo',
		    'd5'  => '/usa/arch',
		},
		'KB2802' => {
		    'd20' => '/starview/dat',
		    'd15' => '/rtd/arch',
		    'd21' => '/starview/dat2',
		    'd28' => '/starview/redo2',
		    'd22' => '/starview/dat3',
		    'd23' => '/starview/dat4',
		},
		'KB3024' => {
		    'd12' => '/rtd/dat3',
		    'd45' => '/superura/arch',
		    'd2'  => '/ura/dat3',
		    'd4'  => '/ura/redo',
		    'd6'  => '/ura/undo',
		},
		'KB4382' => {
		    'd8'  => '/ura/redo4',
		    'd18' => '/rtd/redo2',
		    'd24' => '/superura/redo3',
		    'd9'  => '/ura/redo5',
		    'd17' => '/rtd/redo3',
		    'd27' => '/starview/redo4',
		},
		'KB3950' => {
		    'd41' => '/superura/dat2',
		    'd42' => '/superura/dat3',
		    'd48' => '/superura/redo2',
		},
		'KB3266' => {
		    'd3'  => '/ura/dat4',
		    'd7'  => '/ura/dat5',
		    'd19' => '/rtd/arch2',
		},
	},
	raid_groups => {
		'KB2800' => {
		    '0'  => '/ura/dat1',
		    '1'  => '/rtd/dat2',
		    '3'  => '/yokmst/dat',
		    '5'  => '/superura/dat',
		    '2'  => '/rtd/redo',
		},
		'KB2801' => {
		    '0'  => '/ura/dat2',
		    '1'  => '/rtd/dat1',
		    '2'  => '/superura/redo',
		    '3'  => '/usa/arch',
		},
		'KB2802' => {
		    '0' => '/starview/dat',
		    '1' => '/rtd/arch',
		    '2' => '/starview/dat2',
		    '3' => '/starview/redo2',
		    '4' => '/starview/dat3',
		    '5' => '/starview/dat4',
		},
		'KB3024' => {
		    '0' => '/rtd/dat3',
		    '1' => '/superura/arch',
		    '2' => '/ura/dat3',
		    '4' => '/ura/redo',
		    '9' => '/ura/undo',
		},
		'KB4382' => {
		    '0' => '/ura/redo4',
		    '1' => '/rtd/redo2',
		    '2' => '/superura/redo3',
		    '3' => '/ura/redo5',
		    '4' => '/rtd/redo3',
		    '5' => '/starview/redo4',
		},
		'KB3950' => {
		    '0' => '/superura/dat2',
		    '2' => '/superura/dat3',
		    '3' => '/superura/redo2',
		},
		'KB3266' => {
		    '0'  => '/ura/dat4',
		    '1'  => '/ura/dat5',
		    '2' => '/rtd/arch2',
		},
	},
};

sub new {bless{},+shift}


# If the host of the master DB is registered, and device text is empty,
# the device is set to be NULL(undef).
sub alias_lun {
	my ($host, $device, $device_text) = @_;
	return ($device_text eq '' && %{$db->{luns}{$host}}) ? undef : $device;
}

sub alias_raid_group {
	my ($host, $device, $device_text) = @_;
	return ($device_text eq '' && %{$db->{raid_groups}{$host}}) ? undef : $device;
}

1;
