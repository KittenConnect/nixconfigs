# Example to create a bios compatible gpt partition
{ lib, targetConfig, ... }:
{
  disko.memSize = 3072;

  disko.devices = {
    disk.disk1 = {
      imageSize = "5G";

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
              vg = "ROOT";
            };
          };
        };
      };
    };

    lvm_vg = {
      ROOT = {
        type = "lvm_vg";
        lvs = {

          swap = lib.mkIf (targetConfig ? swap && targetConfig.swap) {
            size = "2G";
            content = {
              type = "swap";
              resumeDevice = (targetConfig ? swapResume && targetConfig.swapResume); # resume from hiberation from this device
            };
          };

          root = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [ "defaults" ];
            };
          };
        };
      };
    };
  };
}
