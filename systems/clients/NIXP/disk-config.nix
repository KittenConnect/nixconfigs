# Example to create a bios compatible gpt partition
{ lib, targetConfig, ... }:
{
  disko.devices = {
    disk.disk1 =
      let
        crypted = targetConfig ? crypted && targetConfig.crypted;

        lv_PV = {
          type = "lvm_pv";
          vg = "ROOT";
        };
      in
      {
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

            root = lib.mkIf (!crypted) {
              size = "100%";

              content = lv_PV;
            };

            cryptroot = lib.mkIf (crypted) {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                extraOpenArgs = [ ];
                passwordFile = "/tmp/secret.key";
                settings = {
                  # if you want to use the key for interactive login be sure there is no trailing newline
                  # for example use `echo -n "password" > /tmp/secret.key`
                  # keyFile = "/tmp/secret.key";
                  allowDiscards = true;
                  # crypttabExtraOpts = [
                  #   "fido2-device=auto"
                  #   "token-timeout=5"
                  # ];
                  # yubikey = {
                  #   slot = 1;
                  #   twoFactor = false; # Set to false for 1FA
                  #   gracePeriod = 5; # Time in seconds to wait for Yubikey to be inserted
                  #   # keyLength = 64; # Set to $KEY_LENGTH/8
                  #   # saltLength = 16; # Set to $SALT_LENGTH

                  #   storage = {
                  #     device = "/dev/nvme0n1p1"; # Be sure to update this to the correct volume
                  #     fsType = "vfat";
                  #     # path = "/crypt-storage/default";
                  #   };
                  # };
                };

                # additionalKeyFiles = [ "/tmp/additionalSecret.key" ];
                content = lv_PV;
              };
            };
          };
        };
      };

    lvm_vg = {
      ROOT = {
        type = "lvm_vg";
        lvs = {

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
