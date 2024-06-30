{ lib, target, config, targetConfig, ... }:
let
  inherit (lib) listToAttrs nameValuePair mkIf mkOption mkEnableOption types;

  # Options

  birdPeerSubmodule = { name, config, ... }: {
    options = {
      enable = mkEnableOption "${name} peer.";

      peerName = mkOption {
        type = types.str;
        default = name;
        description = "Override name of the BGP peer.";
      };

      peerIP = mkOption {
        type = types.str;
        description = "IP address of the BGP peer.";
      };

      peerAS = mkOption {
        type = types.int;
        default = 65666;
        description = "Autonomous System number of the BGP peer.";
      };

      localIP = mkOption {
        type = types.str;
        default = "";
        description = "Local IP address.";
      };

      localAS = mkOption {
        type = types.int;
        default = 65666;
        description = "Local Autonomous System number.";
      };

      multihop = mkOption {
        type = types.int;
        default = 0;
        description = "Multihop TTL value.";
      };

      template = mkOption {
        type = types.str;
        default = "";
        description = "Template string.";
      };

      password = mkOption {
        type = types.str;
        default = "";
        description = "Password for BGP session.";
      };

      passwordRef = mkOption {
        type = types.str;
        default = "";
        description = "Reference to a password for BGP session.";
      };

      ipv4 = mkOption {
        type = types.attrs;
        default = { };
        description = "IPv4 configuration.";
      };

      ipv6 = mkOption {
        type = types.attrs;
        default = { };
        description = "IPv6 configuration.";
      };

      bgpMED = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "BGP Multi Exit Discriminator.";
      };

      # wireguard = mkOption {
      #   type = types.attrs;
      #   default = { };
      #   description = "Wireguard configuration.";
      # };

      interface = mkOption {
        type = types.nullOr types.str;

        description = "Network interface.";
        default = if config.wireguard != { } then
          (if config.wireguard ? interface then
            config.wireguard.interface
          else
            config.peerName)
        else
          null;
      };
    };
  };

  # Values

  peers = config.customModules.bird_peers;

  peersWithPasswordRef = lib.attrsets.filterAttrs (n: v: v ? passwordRef) peers;

  passwords = lib.unique
    (lib.attrsets.mapAttrsToList (n: v: v.passwordRef) peersWithPasswordRef);
in {

  options.customModules.bird_peers = mkOption {
    default = {};
    type = with types;
      attrsOf (submodule
        birdPeerSubmodule); # types.submodule (mkNamedOptionModule birdPeerSubmodule);
    description = "Configuration for BGP peers.";
  };

  config = mkIf (peers != {}) {

    sops.secrets = lib.mkIf (passwords != [ ]) (listToAttrs (map (n:
      lib.nameValuePair "bird_secrets/${n}" {
        reloadUnits = [ "bird2.service" ];
      }) passwords));

    sops.templates."bird_secrets.conf".content = lib.mkIf (passwords != [ ])
      (lib.mkMerge (map (password: ''
        define secretPassword_${password} = "${
          config.sops.placeholder."bird_secrets/${password}"
        }";
      '') passwords));

    services.bird2.config = let
      mkPeersFuncArgs = (x: { peerName = x; } // peers.${x});

      toLines = nindent:
        let indent = lib.concatMapStrings (_: " ") (lib.range 1 nindent);
        in builtins.concatStringsSep ''

          ${indent}'';

      withType = types: x: lib.toFunction types.${builtins.typeOf x} x;

      peersFunc = x@{ peerName, peerIP, peerAS ? 65666,

        localIP ? "", localAS ? 65666,

        multihop ? 0, template ? "",

        password ? "", passwordRef ? "",

        ipv4 ? { }, ipv6 ? { },

        bgpMED ? null,

        wireguard ? { }, interface ? if (wireguard != { }) then
          (if wireguard ? interface then wireguard.interface else peerName)
        else
          null, ... }:
        let
          inherit (lib) optionalString;
          inherit (builtins) concatStringsSep toJSON;
        in ''

          ${optionalString (bgpMED != null)
          "define bgpMED_${toString peerName} = ${toString bgpMED};"}
          ${optionalString (template == "kittunderlay") ''

            filter filter4_IN_BGP_${toString peerName} {
              if is_valid4_network() then {
                if defined( bgp_med ) then
                  bgp_med = bgp_med + bgpMED_${toString peerName};
                else {
                  bgp_med = bgpMED_${toString peerName};
                }
                accept;
              } else reject;
            }

            filter filter6_IN_BGP_${toString peerName} {
              if is_valid6_network() then {
                if defined( bgp_med ) then
                  bgp_med = bgp_med + bgpMED_${toString peerName};
                else {
                  bgp_med = bgpMED_${toString peerName};
                }
                accept;
              } else reject;
            }
          ''}

          # ${optionalString (x ? debug && x.debug == true) (toJSON x)}
          # L: AS${toString localAS} | R: AS${toString peerAS}
          protocol bgp ${toString peerName} ${
            optionalString (template != "") "from ${toString template}"
          } {
            local ${optionalString (localIP != "") (toString localIP)} as ${
              toString localAS
            }; # localIP: "${toString localIP}"
            neighbor ${toString peerIP} as ${toString peerAS};
            ${optionalString (interface != null) ''interface "${interface}";''}
            ${
              if multihop == 0 then
                "direct;"
              else
                "multihop ${
                  optionalString (multihop != -1) toString
                  (if multihop < -1 then -1 * multihop else multihop)
                };"
            } # multihop: ${toString multihop}

            ${
              optionalString (password != "") ''
                password "${
                  assert lib.asserts.assertMsg (passwordRef == "")
                    "U defined a passwordRef, why do you still want to leak password ?";
                  toString (lib.warn
                    "bird2 peers password is insecure consider using passwordRef with a bird_secrets file"
                    password)
                }"; # Not-Secured cleartext access for @everyone''
            }
            ${
              optionalString (passwordRef != "") "password secretPassword_${
                toString passwordRef
              }; # Defined in secrets file"
            }

            ${
              optionalString (ipv6 != { }) ''

                ipv6 {
                  ${
                    optionalString (ipv6 ? imports && ipv6.imports != ""
                      && ipv6.imports != [ ]) (let
                        myType = withType {
                          string = x: "  import ${x};";
                          null = x: "  import none;";
                          lambda = f: myType (f peerName);
                          list = x: ''

                            # ${toJSON x}
                                import filter {
                                  if ( net ~ [ ${
                                    concatStringsSep ", " x
                                  } ] ) then {
                                    accept;
                                  }
                                  reject;
                                };
                          '';
                        };
                      in myType ipv6.imports)
                  }
                  ${
                    optionalString (ipv6 ? exports && ipv6.exports != ""
                      && ipv6.exports != [ ]) (let
                        myType = withType {
                          string = x: "  export ${x};";
                          null = x: "  export none;";
                          lambda = f: myType (f peerName);
                          list = x: ''

                            # ${toJSON x}
                                export filter {
                                  if ( net ~ [ ${
                                    concatStringsSep ", " x
                                  } ] ) then {
                                    accept;
                                  }
                                  reject;
                                };
                          '';
                        };
                      in myType ipv6.exports)
                  }
                  };
              ''
            }

          }
        ''

      ;
    in lib.mkOrder 50 (builtins.concatStringsSep "\n"
      ([ "# Nix-OS Generated for ${target}" ] ++ (map (x: ''
        # ${x}
        ${peersFunc (mkPeersFuncArgs x)}'') (builtins.attrNames peers))));
  };
}
