#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
package Rex::Module::Firecracker::Provider::Default;

use strict;
use warnings;

use Rex -base;
use Rex::Helper::Run;
use Rex::Commands::Fs;
use Rex::Commands::File;
use Rex::File::Parser::Data;
use Rex::Logger;

use boolean;
use Carp;
use JSON::XS;
use Data::Dumper;

sub new {
    my $that  = shift;
    my $proto = ref($that) || $that;
    my $self  = {@_};

    bless( $self, $proto );

    return $self;
}

sub present {
    my ($self, $rule_config) = @_;

    my $changed = 0;
    my $coder = JSON::XS->new->ascii->pretty;

    file "/etc/firecracker",
        ensure => "directory",
        owner => "root",
        group => "root",
        mode => "0700";

    file "/etc/firecracker/$rule_config->{name}.d",
        ensure => "directory",
        owner => "root",
        group => "root",
        mode => "0700";


    file "/etc/firecracker/$rule_config->{name}.d/post-start.sh",
        content => template('@firecracker.post.start',  %{$rule_config}, firecracker_runpath => "/var/run", firecracker_etcpath => "/etc/firecracker"),
        owner => "root",
        group => "root",
        mode => "0750",
        on_change => sub {
            $changed = 1;
        };


    file "/etc/systemd/system/firecracker-console\@$rule_config->{name}.service",
        content => template('@systemd.console.unit', %{$rule_config}, firecracker_runpath => "/var/run"),
        owner => "root",
        group => "root",
        mode => "0640",
        on_change => sub {
            $changed = 1;
            run "systemctl daemon-reload";
        };

    file "/etc/systemd/system/firecracker-$rule_config->{name}.service",
        content => template('@systemd.unit', %{$rule_config}, firecracker_runpath => "/var/run"),
        owner => "root",
        group => "root",
        mode => "0640",
        on_change => sub {
            $changed = 1;
            run "systemctl daemon-reload";
        };

    service "firecracker-$rule_config->{name}.service",
        ensure => "started";


    if ( $rule_config->{drives}->@* ) {
        for my $drive ( $rule_config->{drives}->@* ) {
            file "/etc/firecracker/$rule_config->{name}.d/drive-$drive->{drive_id}.json",
                content => $coder->encode($drive),
                owner => "root",
                group => "root",
                mode => "0640",
                on_change => sub {
                    $changed = 1;
                };
        }
        # TODO: remove existing drives
    }

    if ( $rule_config->{network_interfaces}->@* ) {
        for my $net_iface ( $rule_config->{network_interfaces}->@* ) {
            file "/etc/firecracker/$rule_config->{name}.d/iface-$net_iface->{iface_id}.json",
                content => $coder->encode($net_iface),
                owner => "root",
                group => "root",
                mode => "0640",
                on_change => sub {
                    $changed = 1;
                };
        }
        # TODO: remove existing ifaces
    }

    if ( keys $rule_config->{boot_source}->%* ) {
        file "/etc/firecracker/$rule_config->{name}.d/boot-source.json",
            content => $coder->encode($rule_config->{boot_source}),
            owner => "root",
            group => "root",
            mode => "0640",
            on_change => sub {
                $changed = 1;
            };
    }
    else {
        file "/etc/firecracker/$rule_config->{name}.d/boot-source.json",
            ensure => "absent",
            on_change => sub {
                $changed = 1;
            };
    }

    if ( keys $rule_config->{machine_config}->%* ) {
        file "/etc/firecracker/$rule_config->{name}.d/machine-config.json",
            content => $coder->encode($rule_config->{machine_config}),
            owner => "root",
            group => "root",
            mode => "0640",
            on_change => sub {
                $changed = 1;
            };
    }
    else {
        file "/etc/firecracker/$rule_config->{name}.d/machine-config.json",
            ensure => "absent",
            on_change => sub {
                $changed = 1;
            };
    }

    if ( keys $rule_config->{logger}->%* ) {
        file "/etc/firecracker/$rule_config->{name}.d/logger.json",
            content => $coder->encode($rule_config->{logger}),
            owner => "root",
            group => "root",
            mode => "0640",
            on_change => sub {
                $changed = 1;
            };
    }
    else {
        file "/etc/firecracker/$rule_config->{name}.d/logger.json",
            ensure => "absent",
            on_change => sub {
                $changed = 1;
            };
    }

    if ( keys $rule_config->{mmds_config}->%* ) {
        file "/etc/firecracker/$rule_config->{name}.d/mmds-config.json",
            content => $coder->encode($rule_config->{mmds_config}),
            owner => "root",
            group => "root",
            mode => "0640",
            on_change => sub {
                $changed = 1;
            };
    }
    else {
        file "/etc/firecracker/$rule_config->{name}.d/mmds-config.json",
            ensure => "absent",
            on_change => sub {
                $changed = 1;
            };
    }

    if ( keys $rule_config->{vsock}->%* ) {
        file "/etc/firecracker/$rule_config->{name}.d/vsock.json",
            content => $coder->encode($rule_config->{vsock}),
            owner => "root",
            group => "root",
            mode => "0640",
            on_change => sub {
                $changed = 1;
            };
    }
    else {
        file "/etc/firecracker/$rule_config->{name}.d/vsock.json",
            ensure => "absent",
            on_change => sub {
                $changed = 1;
            };
    }

    if ( keys $rule_config->{metrics}->%* ) {
        file "/etc/firecracker/$rule_config->{name}.d/metrics.json",
            content => $coder->encode($rule_config->{metrics}),
            owner => "root",
            group => "root",
            mode => "0640",
            on_change => sub {
                $changed = 1;
            };
    }
    else {
        file "/etc/firecracker/$rule_config->{name}.d/metrics.json",
            ensure => "absent",
            on_change => sub {
                $changed = 1;
            };
    }

    return $changed;
}

sub absent {
    my ($self, $rule_config) = @_;

    my $changed = 0;

    if ( is_dir("/etc/firecracker/$rule_config->{name}.d") ) {
        rmdir "/etc/firecracker/$rule_config->{name}.d", recursive => 1;
        $changed = 1;

        service "firecracker-$rule_config->{name}",
            ensure => "stopped";

        service "firecracker-console\@$rule_config->{name}",
            ensure => "stopped";

        file "/etc/systemd/system/firecracker-console\@$rule_config->{name}.service",
            ensure => "absent",
            on_change => sub {
                $changed = 1;
                run "systemctl daemon-reload";
            };

        file "/etc/systemd/system/firecracker-$rule_config->{name}.service",
            ensure => "absent",
            on_change => sub {
                $changed = 1;
                run "systemctl daemon-reload";
            };
    }

    return $changed;
}

1;


__DATA__

@systemd.unit
[Unit]
Description=Firecracker
Requires=firecracker-console@<%= $name %>.service
After=firecracker-console@<%= $name %>.service

[Service]
Type=exec
ExecStart=firecracker --api-sock <%= $firecracker_runpath %>/firecracker-<%= $name %>.socket
ExecStartPost=/etc/firecracker/<%= $name %>.d/post-start.sh
ExecStopPost=rm -f <%= $firecracker_runpath %>/firecracker-<%= $name %>.socket
StandardInput=tty-force
StandardOutput=inherit
TTYPath=<%= $firecracker_runpath %>/firecracker-tty-int-<%= $name %>
@end

@systemd.console.unit
[Unit]
Description=Firecracker Console

[Service]
Type=exec
ExecStart=socat PTY,link=<%= $firecracker_runpath %>/firecracker-tty-int-<%= $name %>,echo=0,wait-slave PTY,link=<%= $firecracker_runpath %>/firecracker-tty-<%= $name %>,echo=0,wait-slave
@end

@firecracker.post.start
#!/bin/bash
# give vmm time
sleep 1

if [ -f "<%= $firecracker_etcpath %>/<%= $name %>.d/boot-source.json" ]; then
    curl --unix-socket <%= $firecracker_runpath %>/firecracker-<%= $name %>.socket \
        -i \
        -XPUT \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        http://localhost/boot-source \
        -d@<%= $firecracker_etcpath %>/<%= $name %>.d/boot-source.json
fi

if [ -f "<%= $firecracker_etcpath %>/<%= $name %>.d/machine-config.json" ]; then
    curl --unix-socket <%= $firecracker_runpath %>/firecracker-<%= $name %>.socket \
        -i \
        -XPUT \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        http://localhost/machine-config \
        -d@<%= $firecracker_etcpath %>/<%= $name %>.d/machine-config.json
fi

if [ -f "<%= $firecracker_etcpath %>/<%= $name %>.d/logger.json" ]; then
    curl --unix-socket <%= $firecracker_runpath %>/firecracker-<%= $name %>.socket \
        -i \
        -XPUT \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        http://localhost/logger \
        -d@<%= $firecracker_etcpath %>/<%= $name %>.d/logger.json
fi

if [ -f "<%= $firecracker_etcpath %>/<%= $name %>.d/mmds-config.json" ]; then
    curl --unix-socket <%= $firecracker_runpath %>/firecracker-<%= $name %>.socket \
        -i \
        -XPUT \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        http://localhost/mmds/config \
        -d@<%= $firecracker_etcpath %>/<%= $name %>.d/mmds-config.json
fi

if [ -f "<%= $firecracker_etcpath %>/<%= $name %>.d/vsock.json" ]; then
    curl --unix-socket <%= $firecracker_runpath %>/firecracker-<%= $name %>.socket \
        -i \
        -XPUT \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        http://localhost/vsock \
        -d@<%= $firecracker_etcpath %>/<%= $name %>.d/vsock.json
fi

if [ -f "<%= $firecracker_etcpath %>/<%= $name %>.d/metrics.json" ]; then
    curl --unix-socket <%= $firecracker_runpath %>/firecracker-<%= $name %>.socket \
        -i \
        -XPUT \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        http://localhost/metrics \
        -d@<%= $firecracker_etcpath %>/<%= $name %>.d/metrics.json
fi


for drive in <%= $firecracker_etcpath %>/<%= $name %>.d/drive-*.json; do
    f_name=$(basename $drive)
    drive_id=$(echo $f_name | sed -e 's/^drive\-//' | sed -e 's/\.json$//')
    curl --unix-socket <%= $firecracker_runpath %>/firecracker-<%= $name %>.socket \
        -i \
        -XPUT \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        http://localhost/drives/${drive_id} \
        -d@${drive}
done

for iface in <%= $firecracker_etcpath %>/<%= $name %>.d/iface-*.json; do
    f_name=$(basename $iface)
    iface_id=$(echo $f_name | sed -e 's/^iface\-//' | sed -e 's/\.json$//')
    curl --unix-socket <%= $firecracker_runpath %>/firecracker-<%= $name %>.socket \
        -i \
        -XPUT \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        http://localhost/network-interfaces/${iface_id} \
        -d@${iface}
done

curl --unix-socket <%= $firecracker_runpath %>/firecracker-<%= $name %>.socket -i -XPUT -H 'Accept: application/json' -H 'Content-Type: application/json' http://localhost/actions -d '{"action_type":"InstanceStart"}'
@end