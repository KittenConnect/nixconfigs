args@{
  lib,
  pkgs,
  config,
  profile,
  ...
}:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.strings) optionalString splitString concatStringsSep;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.kitten.strings) indentedLines;
  inherit (lib) types mkAfter;

  quoteString = x: ''"${x}"'';
  spaces = n: lib.concatMapStrings (x: " ") (lib.range 1 n);
  indented = n: s: concatStringsSep "\n${spaces n}" (splitString "\n" s);

  mkEnabledOption =
    desc:
    lib.mkEnableOption desc
    // {
      example = false;
      default = true;
    };

  mkRule = { rule, comment }: ''${rule} comment "${comment}"'';

  profilesPath = ./profiles;
  profiles = lib.pipe (import profilesPath args).imports [
    (map builtins.baseNameOf)
    (map (lib.removeSuffix ".nix"))
  ];

  cfg = config.kittenModules.firewall;
in
{
  options.kittenModules.firewall = {
    enable = mkEnabledOption "KittenConnect common firewall module";

    forward = {
      enable = mkEnabledOption "KittenConnect common firewall forward rules";

      stateless = mkEnableOption "Forwarding rules not using conntrack";
      keepInvalidState = mkEnableOption "Try invalid state packets in forwarding rules instead of droping them directly";
      allowDnat = mkEnabledOption "Forwarding Rule allowing DNAT-ed packets";
      allowICMP = mkEnabledOption "Forwarding Rule allowing ICMP packets";

      chain = mkOption {
        type = types.str;
        default = "forward-rules";
      };

      variables = mkOption {
        type = types.attrsOf types.str;
        default = { };
      };

      rules = mkOption {
        type = types.lines;
        default = "";
      };
    };

    profile = mkOption {
      type = types.enum ([ "" ] ++ profiles);
      default = "";
    };
  };

  imports = [
    profilesPath
  ];

  config = lib.mkIf (cfg.enable) {
    _module.args = {
      inherit mkRule;
    };
    networking.nftables = {
      enable = true;

      tables."nixos-fw".content = lib.mkIf (cfg.forward.enable) (
        mkAfter (
          let
            fwVars = mapAttrsToList (k: v: ''define ${k} = ${v}'') cfg.forward.variables;

            gotoRules = "jump ${cfg.forward.chain}";
            vmapRules = ''
              ct state vmap {
                established: accept, related: accept, 
                new: ${gotoRules}, untracked: ${gotoRules},
                invalid: ${if cfg.forward.keepInvalidState then gotoRules else "drop"},
              }
            '';

            allowICMP = optionalString (cfg.forward.allowICMP) (mkRule {
              comment = "Accept all ICMPv6 messages except renumbering and node information queries (type 139).  See RFC 4890, section 4.3.";
              rule = "icmpv6 type != { router-renumbering, 139 } accept";
            });

            allowDNAT = optionalString (cfg.forward.allowDnat) (mkRule {
              comment = "Accept all DNAT-marked packet in ConnTrack.";
              rule = "ct status dnat accept";
            });
          in
          ''
            # Kitten NixOS Forward rules 
            ${concatStringsSep "\n" fwVars}

            chain forward {
              type filter hook forward priority filter; policy drop;
              ${if cfg.forward.stateless then gotoRules else indented 2 vmapRules}
            }

            chain ${cfg.forward.chain} {
              ${allowICMP}
              ${allowDNAT}

              ${indented 2 cfg.forward.rules}
            }
          ''
        )
      );
    };
  };
}
