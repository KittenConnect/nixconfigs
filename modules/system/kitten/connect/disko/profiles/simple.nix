# Example to create a bios compatible gpt partition
args@{ lib, config, ... }:
let
  inherit (builtins) baseNameOf; # unsafeGetAttrPos;
  inherit (lib)
    types
    optionalAttrs
    mkOption
    mkEnableOption
    ;
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

    efiSize = mkOption {
      type = types.int;
      default = 512;
      description = "EFI size (in MB)";
    };

    swapSize = mkOption {
      type = types.int;
      default = 0;
      description = "SWAP size (in MB) [0 = OFF]";
    };

    lvm = {
      vg = mkOption {
        type = types.str;
        default = "ROOT";
      };
    };
    crypted = mkEnableOption "luks disk encryption";

    swapResume = mkEnableOption "Resume from swap" // {
      default = if profileConf.swapSize > 0 then true else false;
    };
  };

  # Implementation
  config = lib.mkIf (cfg.enable && cfg.profile == profileName) {
    disko.memSize = 3072; # needed moar ram for build

    disko.devices = {
      disk.disk1 = {
        imageSize = "5G";

        device = lib.mkDefault "${profileConf.bootdisk}";
        type = "disk";
        content = {
          type = "gpt";
          partitions =
            let
              lvmRootPV = {
                type = "lvm_pv";
                vg = profileConf.lvm.vg;
              };
            in
            { # Common setup (/boot + EFI)
              boot = {
                size = "1M";
                type = "EF02"; # for grub MBR
              };

              ESP = {
                size = "${toString profileConf.efiSize}M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              };
            }
            // (optionalAttrs (!profileConf.crypted) { # Plain PV
              root = {
                size = "100%";
                content = lvmRootPV;
              };
            })
            // (optionalAttrs (profileConf.crypted) { # LUKS PV
              cryptroot = {
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
                  };

                  # additionalKeyFiles = [ "/tmp/additionalSecret.key" ];
                  content = lvmRootPV;
                };
              };
            });
        };
      };

      # LVM settings
      lvm_vg = {
        "${profileConf.lvm.vg}" = {
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
