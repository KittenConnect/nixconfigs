# Example to create a bios compatible gpt partition
{ lib, bootdisk, ... }:
{
  disko.devices = {
    disk.disk1 = {
      device = lib.mkDefault "${bootdisk}";
      type = "disk";
      content = {
        type = "table";
        format = "msdos";
        partitions = [
          {
            name = "boot";
            start = "1M";
            end = "500M";
            part-type = "primary";
            bootable = true;
            content = {
              type = "filesystem";
              format = "ext3";
              mountpoint = "/boot";
            };
          }
          {
            name = "root";
            start = "500M";
            part-type = "primary";
            end = "100%";
            content = {
              type = "lvm_pv";
              vg = "SSD";
            };
          }
        ];
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
            size = "20G";
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
