args@{
  lib,
  kittenLib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.options) mkOption;
  inherit (lib.strings)
    optionalString
    splitString
    concatMapStringsSep
    concatStringsSep
    ;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (kittenLib.strings) quotedString indentedLines;
  inherit (lib) types mkAfter;

  baseTable = "nixos-fw";

  mkRule =
    args:
    args
    // {
      __toString =
        {
          rule,
          comment,
          ...
        }:
        ''${rule} comment "${comment}"'';
    };

  setsPerTables = lib.foldl (
    acc:
    {
      name,
      value,
    }:
    acc
    // {
      "${value.table}" = (acc.${value.table} or { }) // {
        "${name}" = value;
      };
    }
  ) { } (lib.attrsToList cfg.forward.sets);

  mkSet = setName: set: ''
    set ${setName} {
      ${optionalString (set.setType != null) "type ${set.setType}"}${
        optionalString (set.setTypeOf != null) "typeof ${set.setTypeOf}"
      }
      ${optionalString (set.flags != [ ]) "flags ${concatStringsSep ", " set.flags}"}
      ${optionalString (set.elements != [ ])
        "elements = { ${concatMapStringsSep ", " builtins.toString set.elements} }"
      }
      ${optionalString (set.extraConfig != "") (indentedLines 2 set.extraConfig)}
    }
  '';

  cfg = config.kittenModules.firewall;
in
{
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
        default = { };
      };

      sets = mkOption {
        type =
          with types;
          attrsOf (
            submodule (
              {
                name,
                config,
                ...
              }:
              {
                options = {
                  setType = mkOption {
                    default = null;
                    type =
                      with types;
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
                    type =
                      with types;
                      listOf (enum [
                        "constant" # set content may not change while bound
                        "interval" # set contains intervals
                        "timeout" # elements can be added with a timeout
                      ]);
                    default = [ ];
                  };

                  elements = mkOption {
                    type =
                      with types;
                      listOf (oneOf [
                        str
                        int
                      ]);
                    default = [ ];
                  };

                  extraConfig = mkOption {
                    type = types.lines;
                    default = "";
                  };
                };
              }
            )
          );

        default = { };
      };

      rules = mkOption {
        type = types.lines;
        default = "";
      };

      nat = {
        netmaps = mkOption {
          type = with types; attrsOf str;
          default = { };
        };

        srcRules = mkOption {
          type = types.lines;
          default = "";
        };

        dstRules = mkOption {
          type = types.lines;
          default = "";
        };
      };
    };
  };

  imports = [ ];

  config = lib.mkIf (cfg.enable) {
    _module.args = {
      inherit mkRule;
    };

    assertions = lib.mapAttrsToList (n: v: {
      assertion =
        (v.setTypeOf == null && v.setType != null) || (v.setTypeOf != null && v.setType != null);
      message = "NFTables set ${v.table}.${n} needs exactly one of setType/setTypeOf";
    }) cfg.forward.sets;

    kittenModules.firewall.forward = {
      sets = {
        kittenIFACEs = {
          setType = "ifname";
          elements = [ ];
        };

        # nat_ranges = {
        #   setType = "ipv4_addr";
        #   table = "nat4";
        #   flags = [ "interval" ];
        # };
      };

      rules = ''
        iifname @kittenIFACEs oifname @kittenIFACEs counter accept
      '';
    };

    networking.firewall.enable = true;
    networking.nftables = {
      enable = true;
      # extraDeletions = lib.mkAfter ''
      #   # Declare global Sets
      #   ${lib.concatMapAttrsStringSep "\n" mkSet setsPerTables.global}
      # '';
      tables = lib.mkMerge [
        (lib.mapAttrs (table: sets: {
          content = lib.mkBefore ''
            # Declare Table Sets for ${table}
            ${lib.concatMapAttrsStringSep "\n" mkSet sets}
          '';
        }) (builtins.removeAttrs setsPerTables [ "global" ]))

        {
          "${baseTable}".content = lib.mkIf (cfg.forward.enable) (
            mkAfter (
              let
                fwVars = mapAttrsToList (k: v: "define ${k} = ${v}") cfg.forward.variables;

                invalid = if cfg.forward.keepInvalidState then gotoRules else "drop";
                gotoRules = "jump ${cfg.forward.chain}";
                vmapRules = ''
                  ct state vmap {
                    established: accept, related: accept,
                    new: ${gotoRules}, untracked: ${gotoRules},
                    invalid: ${invalid},
                  }
                '';
                defaultPolicy = if cfg.forward.stateless then gotoRules else indentedLines 2 vmapRules;

                allowICMP = mkRule {
                  comment = "Accept all ICMPv6 messages except renumbering and node information queries (type 139).  See RFC 4890, section 4.3.";
                  rule = "icmpv6 type != { router-renumbering, 139 } accept";
                };

                allowDNAT = mkRule {
                  comment = "Accept all DNAT-marked packet in ConnTrack.";
                  rule = "ct status dnat accept";
                };
              in
              ''
                chain early-inbound {
                  type filter hook prerouting priority raw; policy accept;

                  # When VRF interfaces are in use, packets go through the prerouting hook
                  # twice, once with the VRF interface set as input and another time with
                  # actual interface set as input.
                  meta iifkind "vrf" return
                }

                chain srcnat {
                  type nat hook postrouting priority srcnat; policy accept;
                  ${optionalString (cfg.forward.nat.netmaps != { }) ''
                    oifname @transitIFACEs snat ip6 prefix to ip6 saddr map { ${
                      concatMapStringsSep ", " ({ name, value }: "${value} : ${name}") (
                        lib.attrsToList cfg.forward.nat.netmaps
                      )
                    } }
                  ''}
                  ${indentedLines 2 cfg.forward.nat.srcRules}
                }

                chain dstnat {
                  type nat hook prerouting priority dstnat; policy accept;
                  ${optionalString (cfg.forward.nat.netmaps != { }) ''
                    iifname @transitIFACEs dnat ip6 prefix to ip6 daddr map { ${
                      concatMapStringsSep ", " ({ name, value }: "${name} : ${value}") (
                        lib.attrsToList cfg.forward.nat.netmaps
                      )
                    } }
                  ''}
                  ${indentedLines 2 cfg.forward.nat.dstRules}
                }

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
                  
                  limit rate 120/minute burst 300 packets log prefix "${cfg.forward.chain}: default policy match: " level info
                  iifname @kittenIFACEs reject comment "reject internal instead of default policy"
                }
              ''
            )
          );
        }
      ];
    };
  };
}
