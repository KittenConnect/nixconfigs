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

      bindCarrier = mkOption {
        type = with types; nullOr str;
        default = cfg.requiredLink;
        description = "defines an interface to up before the VRF";
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

    requiredLink = mkOption {
      type = types.str;
      default = "lo";
      description = "defines the default interface to up before the VRFs";
    };

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
              networkConfig = {
                LinkLocalAddressing = false;
                BindCarrier = vrf.bindCarrier;
              };

              routingPolicyRules = builtins.map (addr: {
                  Family = if lib.hasInfix ":" addr then "ipv6" else "ipv4";
                  From = addr;
                  IncomingInterface = "lo";
                  Table = vrf.tableID;
              }) (builtins.filter (addr: !(lib.hasPrefix "::1/" addr || lib.hasPrefix "127.0.0.1/" addr)) vrf.address);
            }
        )
        vrfTables;
    };
  };
}
