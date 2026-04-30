args @ {
  lib,
  kittenLib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit
    (lib.strings)
    optionalString
    splitString
    concatMapStringsSep
    concatStringsSep
    ;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (kittenLib.strings) quotedString indentedLines;
  inherit (lib) types mkAfter;

  baseTable = "nixos-fw";

  mkRule = args:
    args
    // {
      __toString = {
        rule,
        comment,
        ...
      }: ''${rule} comment "${comment}"'';
    };

  cfg = config.kittenModules.firewall;
in {
  options.kittenModules.firewall = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "KittenConnect common firewall module";
    };

    forward = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "KittenConnect common firewall forward rules";
      };

      stateless = mkOption {
        type = types.bool;
        default = false;
        description = "Forwarding rules not using conntrack";
      };
      keepInvalidState = mkOption {
        type = types.bool;
        default = false;
        description = "Try invalid state packets in forwarding rules instead of droping them directly";
      };
      allowDnat = mkOption {
        type = types.bool;
        default = false;
        description = "Forwarding Rule allowing DNAT-ed packets";
      };
      allowICMP = mkOption {
        type = types.bool;
        default = false;
        description = "Forwarding Rule allowing ICMP packets";
      };

      chain = mkOption {
        type = types.str;
        default = "forward-rules";
      };

      variables = mkOption {
        type = types.attrsOf types.str;
        default = {};
      };

      sets = mkOption {
        type = with types;
          attrsOf (
            submodule (
              {
                name,
                config,
                ...
              }: {
                options = {
                  setType = mkOption {
                    default = null;
                    type = with types;
                      nullOr (enum [
                        "ipv4_addr" # IPv4 address
                        "ipv6_addr" # IPv6 address.
                        "ether_addr" # Ethernet address.
                        "inet_proto" # Inet protocol type.
                        "inet_service" # Internet service (read tcp port for example)
                        "mark" # Mark type.
                        "ifname" # Network interface name (eth0, eth1..)
                      ]);
                  };
                  setTypeOf = mkOption {
                    default = null;
                    type = with types; nullOr str;
                  };

                  table = mkOption {
                    type = types.str;
                    default = baseTable;
                  };

                  flags = mkOption {
                    type = with types;
                      listOf (enum [
                        "constant" # set content may not change while bound
                        "interval" # set contains intervals
                        "timeout" # elements can be added with a timeout
                      ]);
                    default = [];
                  };

                  elements = mkOption {
                    type = with types;
                      listOf (oneOf [
                        str
                        int
                      ]);
                    default = [];
                  };

                  extraConfig = mkOption {
                    type = types.lines;
                    default = "";
                  };
                };
              }
            )
          );

        default = {};
      };

      rules = mkOption {
        type = types.lines;
        default = "";
      };

      natRules = mkOption {
        type = types.lines;
        default = "";
      };
    };
  };

  imports = [];

  config = lib.mkIf (cfg.enable) {
    _module.args = {
      inherit mkRule;
    };

    assertions =
      lib.mapAttrsToList (n: v: {
        assertion =
          (v.setTypeOf == null && v.setType != null) || (v.setTypeOf != null && v.setType != null);
        message = "NFTables set ${v.table}.${n} needs exactly one of setType/setTypeOf";
      })
      cfg.forward.sets;

    kittenModules.firewall.forward = {
      sets = {
        wan_iface = {
          setType = "ifname";
          table = "nat";
        };

        kittenIFACEs = {
          setType = "ifname";
          elements = [];
        };

        nat_ranges = {
          setType = "ipv4_addr";
          table = "nat";
          flags = ["interval"];
        };
      };

      rules = ''
        iifname @kittenIFACEs oifname @kittenIFACEs counter accept
      '';
    };

    networking.firewall.enable = true;
    networking.nftables = {
      enable = true;

      tables = let
        setsPerTables = lib.foldl (
          acc: {
            name,
            value,
          }:
            acc
            // {
              "${value.table}" =
                (acc.${value.table} or {})
                // {
                  "${name}" = value;
                };
            }
        ) {} (lib.attrsToList cfg.forward.sets);
      in
        lib.mkMerge [
          {
            "nat" = {
              family = "inet";
              content = ''
                chain srcnat {
                  type nat hook postrouting priority srcnat; policy accept;
                  ${indentedLines 2 cfg.forward.natRules}
                }
              '';
            };
          }

          (lib.mapAttrs (table: sets: {
              content = lib.mkBefore ''
                # Declare Table Sets for ${table}
                ${lib.concatMapAttrsStringSep "\n" (setName: set: ''
                    set ${setName} {
                      ${optionalString (set.setType != null) "type ${set.setType}"}${
                      optionalString (set.setTypeOf != null) "typeof ${set.setTypeOf}"
                    }
                      ${optionalString (set.flags != []) "flags ${concatStringsSep ", " set.flags}"}
                      ${
                      optionalString (set.elements != [])
                      "elements = { ${concatMapStringsSep ", " builtins.toString set.elements} }"
                    }
                      ${optionalString (set.extraConfig != "") (indentedLines 2 set.extraConfig)}
                    }
                  '')
                  sets}
              '';
            })
            setsPerTables)

          {
            "${baseTable}".content = lib.mkIf (cfg.forward.enable) (
              mkAfter (
                let
                  fwVars = mapAttrsToList (k: v: "define ${k} = ${v}") cfg.forward.variables;

                  invalid =
                    if cfg.forward.keepInvalidState
                    then gotoRules
                    else "drop";
                  gotoRules = "jump ${cfg.forward.chain}";
                  vmapRules = ''
                    ct state vmap {
                      established: accept, related: accept,
                      new: ${gotoRules}, untracked: ${gotoRules},
                      invalid: ${invalid},
                    }
                  '';
                  defaultPolicy =
                    if cfg.forward.stateless
                    then gotoRules
                    else indentedLines 2 vmapRules;

                  allowICMP = mkRule {
                    comment = "Accept all ICMPv6 messages except renumbering and node information queries (type 139).  See RFC 4890, section 4.3.";
                    rule = "icmpv6 type != { router-renumbering, 139 } accept";
                  };

                  allowDNAT = mkRule {
                    comment = "Accept all DNAT-marked packet in ConnTrack.";
                    rule = "ct status dnat accept";
                  };
                in ''
                  # Kitten NixOS Forward rules
                  ${concatStringsSep "\n" fwVars}

                  chain forward {
                    type filter hook forward priority filter; policy drop;
                    ${defaultPolicy}
                  }

                  chain ${cfg.forward.chain} {
                    ${optionalString (cfg.forward.allowICMP) allowICMP}
                    ${optionalString (cfg.forward.allowDnat) allowDNAT}

                    ${indentedLines 2 cfg.forward.rules}
                    iifname @kittenIFACEs log prefix "refused connection: " level info reject comment "reject internal instead of default policy"
                  }
                ''
              )
            );
          }
        ];
    };
  };
}
