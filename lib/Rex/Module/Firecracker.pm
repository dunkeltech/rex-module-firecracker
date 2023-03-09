#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

=head1 NAME

Rex::Module::Firecracker

=head1 DESCRIPTION

Manage Firecracker microVMs with Rex.

=head1 SYNOPSIS

    use Rex::Module::Firecracker;
    use JSON::XS;

    task create_vm => group => ["node1"] => sub {
        firecracker "test",
            ensure => "present",
            boot_source => {
                kernel_image_path => "/opt/kernel/vmlinux.bin"
            },
            drives => [
                {
                    drive_id => "rootfs",
                    path_on_host => "/srv/images/demo.img",
                    is_root_device => $JSON::XS::true,
                    is_read_only => $JSON::XS::false,
                }
            ];
    };

=head1 EXPORTED RESOURCES

=cut

package Rex::Module::Firecracker;

use strict;
use warnings;

use Rex -minimal;
use Rex::Resource::Common;
use Rex::Commands::Gather;

use Carp;
use boolean;
use JSON::XS;

my $__provider = {
    default => "Rex::Module::Firecracker::Provider::Default"
};

my $MACHINE_CONFIG_DEFAULTS = {
    vcpu_count => 2,
    mem_size_mib => 1024,
    smt => $JSON::XS::false,
    track_dirty_pages => $JSON::XS::false
};

=head2 firecracker

This resource creates a firecracker microVM on the host and starts it. It will also create systemd units so that it will start again if the server is rebooted.

=over 4

=item name

Sets the name of the resource

=item ensure

Whether the resource should be present or absent

=item boot_source

Boot source configuration

=item drives

Drives configuration

=item machine_config

Machine configuration

=item balloon

Balloning configuration

=item network_interfaces

Network interface configuration

=item vsock

VSock configuration

=item logger

Logger configuration

=item metrics

Metrics configuration

=item mmds_config

MMDS configuration

=back

To see which options you can use, check out the firecracker documentation at https://github.com/firecracker-microvm/firecracker/blob/main/tests/framework/vm_config.json.

=cut

resource "firecracker", { export => 1 }, sub {
    my $resource_name = resource_name;

    my $rule_config = {
        name => $resource_name,
        ensure => param_lookup( "ensure", "present" ),
        boot_source => param_lookup( "boot_source", {} ),
        drives => param_lookup( "drives", [] ),
        machine_config => param_lookup( "machine_config", $MACHINE_CONFIG_DEFAULTS ),
        balloon => param_lookup( "balloon", {} ),
        network_interfaces => param_lookup( "network_interfaces", [] ),
        vsock => param_lookup( "vsock", {} ),
        logger => param_lookup( "logger", {} ),
        metrics => param_lookup( "metrics", {} ),
        mmds_config => param_lookup( "mmds_config", {} ),
    };

    if ( !$rule_config->{boot_source} ) {
        confess "You have to define a boot source with a leat a kernel_image.";
    }
    if ( !$rule_config->{drives} || scalar @{ $rule_config->{drives} } == 0 ) {
        confess "You have to define a boot source with a leat a kernel_image.";
    }

    $rule_config->{boot_source}->{boot_args} //= "console=ttyS0 reboot=k panic=1 pci=off";

    my $provider = param_lookup( "provider", case ( lc(operating_system), $__provider ) );

    $provider->require;

    my $provider_o = $provider->new();

    if ( $rule_config->{ensure} eq "present" ) {
        if ( $provider_o->present($rule_config) ) {
            emit created, "Firecracker $resource_name created.";
        }
    }
    elsif ( $rule_config->{ensure} eq "absent" ) {
        if ( $provider_o->absent($rule_config) ) {
            emit removed, "Firecracker $resource_name removed.";
        }
    }
    else {
        confess "Ensure must be one of present or absent";
    }

};

