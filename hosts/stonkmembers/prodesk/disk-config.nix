# Example to create a bios compatible gpt partition
{ lib, targetConfig, ... }:
{
  disko.devices = {
    disk.disk1 = {
      device = lib.mkDefault "${targetConfig.bootdisk}";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02"; # for grub MBR
          };

          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };

          root = {
            size = "100%";
            content = {
              type = "lvm_pv";
              vg = "SSD";
            };
          };
        };
      };
    };
    lvm_vg = {
      SSD = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "15G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [ "defaults" ];
            };
          };
          k3s = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/var/lib/rancher";
              mountOptions = [ "defaults" ];
            };
          };
        };
      };
    };
  };
}
