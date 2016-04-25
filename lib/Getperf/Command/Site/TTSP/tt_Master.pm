package Getperf::Command::Master::TTSP;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw/alias_lun alias_raid_group/;

our $db = {
	_node_dir   => undef,
	controllers => undef,
	luns        => undef,
	raid_groups => undef,
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

	return ($device_text eq '' && $db->{raid_groups}{$host}) ? undef : $device;
}

1;
