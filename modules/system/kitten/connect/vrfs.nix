{
  lib,
  kittenLib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;

  vrfSubmodule = {
    name,
    config,
    ...
  }: {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        example = false;
        description = "${name} peer.";
      };

      iface = mkOption {
        type = types.str;
        default = name;
        description = "Override name of the VRF interface.";
      };

      tableID = mkOption {
        type = types.int;
        description = "table ID used for this VRF interface";
      };

      address = mkOption {
        type = types.listOf types.str;
        default = [];
      };
    };

    config = {
      address = [
        "127.0.0.1/8"
        "::1/128"
      ];
    };
  };

  vrfTables = lib.filterAttrs (n: v: v.enable) cfg.tables;
  hasVRF = vrfTables != {};

  cfg = config.kittenModules.vrfs;
in {
  options.kittenModules.vrfs = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "VRF interfaces module";
    };
    # hosts = mkOption { type = types.bool; default = false; description = "hosts entry for each loopback IP"; };

    tables = lib.mkOption {
      type = with lib.types; attrsOf (submodule vrfSubmodule);
      default = {};
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.etc."iproute2/rt_tables.d/nix_vrfs.conf" = lib.mkIf hasVRF {
      text = ''
        # NixOS managed VRFs + Tables
        ${lib.concatMapAttrsStringSep "\n" (
            vrfName: vrf: "${builtins.toString vrf.tableID} ${vrf.iface} # ${vrfName}"
          )
          vrfTables}
      '';
    };

    systemd.network = lib.mkIf hasVRF {
      netdevs =
        lib.mapAttrs' (
          vrfName: vrf:
            lib.nameValuePair "10-${vrf.iface}" {
              netdevConfig = {
                Kind = "vrf";
                Name = vrf.iface;
              };

              vrfConfig = {
                Table = vrf.tableID;
              };
            }
        )
        vrfTables;

      networks =
        lib.mapAttrs' (
          vrfName: vrf:
            lib.nameValuePair "15-${vrf.iface}" {
              matchConfig.Name = vrf.iface;
              address = vrf.address;
              networkConfig.LinkLocalAddressing = false;
            }
        )
        vrfTables;
    };
  };
}
