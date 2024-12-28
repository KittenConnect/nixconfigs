# Example to create a bios compatible gpt partition
args@{ lib, config, ... }:
let
  inherit (builtins) baseNameOf; # unsafeGetAttrPos;
  inherit (lib) types mkOption mkEnableOption;
  inherit (lib.strings) removeSuffix;
  # inherit (lib.attrsets) filterAttrs attrNames;

  fileName = baseNameOf (__curPos).file; # (__curPos) or (unsafeGetAttrPos "args" { inherit args; })
  profileName = lib.strings.removeSuffix ".nix" fileName;

  cfg = config.kittenModules.disko;
  profileConf = config.kittenModules.disko.${profileName};
in
{
  # Module Options
  options.kittenModules.disko.${profileName} = {
    bootdisk = mkOption {
      type = types.str;
    };

    swapSize = mkOption {
      type = types.int;
      default = 0;
    };

    swapResume = mkEnableOption "Resume from swap" // {
      default = if profileConf.swapSize > 0 then true else false;
    };
  };

  # Implementation
  config = lib.mkIf (cfg.enable && cfg.profile == profileName) {
    disko.memSize = 3072;

    disko.devices = {
      disk.disk1 = {
        imageSize = "5G";

        device = lib.mkDefault "${profileConf.bootdisk}";
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

            swap = lib.mkIf (profileConf.swapSize > 0) {
              size = "${toString profileConf.swapSize}M";
              content = {
                type = "swap";
                resumeDevice = profileConf.swapResume; # resume from hiberation from this device
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
  };
}
