# Firecracker Rex Module

Manage Firecracker microVMs with Rex.

Firecracker is a virtual machine monitor developed by Amazon to run their Fargate and Lambda services.

With Firecracker you can run your services inside a microVM based on KVM with all the security KVM provides.

## Example

```perl
#!/usr/bin/env perl

use Rex -feature => ['1.4'];

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
```
