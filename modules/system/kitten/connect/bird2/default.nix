args @ {
  lib,
  kittenLib,
  pkgs,
  config,
  name,
  ...
}: let
  inherit
    (lib)
    optional
    optionals
    optionalString
    mkOrder
    mkDefault
    attrNames
    filterAttrs
    concatStringsSep
    concatMapStringsSep
    listToAttrs
    nameValuePair
    mkMerge
    mkIf
    mkOption
    mkEnableOption
    types
    unique
    mapAttrsToList
    isType
    ;

  inherit (kittenLib.strings) indentedLines quotedString;

  withType = types: x: lib.toFunction types.${builtins.typeOf x} x;

  # Main config is here
  cfg = config.kittenModules.bird;

  # Values
  peers = cfg.peers;
  peersWithPasswordRef = filterAttrs (n: v: v.passwordRef != null) peers;
  peersRouteReflectors = attrNames (filterAttrs (n: v: v.template == "rrserver") peers);

  passwords = unique (mapAttrsToList (n: v: v.passwordRef) peersWithPasswordRef);

  directInterfaces = let noLoopback = (builtins.elem "-lo" cfg.interfaces); in
    if (cfg.interfaces != null)
    then
      lib.concatMapStringsSep ", " quotedString (
        (optional (!(noLoopback) && (cfg.loopback4 != null || cfg.loopback6 != null)) "lo")
        ++ cfg.interfaces
        ++ (optional (builtins.all (lib.hasPrefix "-") cfg.interfaces) "*")
      )
    else quotedString "*";

  # Example
  # config.kittenModules.bird = {
  #   # Example values, replace with actual srvCfg structure
  #   peers = {
  #     peer1 = { template = "rrserver"; };
  #     peer2 = { template = "other"; };
  #   };
  #   loopback4 = "192.0.2.1";
  #   loopback6 = "2001:db8::1";
  #   transitInterface = "eth0";
  #   static6 = [ "2001:db8::2" ];
  # };
in {
  imports = [
    ./server_config.nix
    ./secrets.nix
  ];

  # Options
  options.kittenModules.bird = import ./options.nix args;

  # Implementation
  config = mkIf cfg.enable {
    _module.args = {
      birdConfig = cfg;

      birdFuncs = {
        inherit quotedString;
      };
    };

    # Firewalling
    networking.firewall.allowedTCPPorts = [
      179 # BGP
      1790 # Internal BGP
    ];

    # Service configuration
    services.bird2 = {
      enable = cfg.enable;

      preCheckConfig = ''
        echo "Found the following include in bird configuration" >&2
        grep include bird2.conf >&2 || true
        echo "EOF" >&2
      '';

      config = mkMerge (
        [
          (mkOrder 0 ''
            log syslog all;


            # The Device protocol is not a real routing protocol. It does not generate any
            # routes and it only serves as a module for getting information about network
            # interfaces from the kernel. It is necessary in almost any configuration.
            protocol device DEV {}

            # The direct protocol is not a real routing protocol. It automatically generates
            # direct routes to all network interfaces. Can exist in as many instances as you
            # wish if you want to populate multiple routing tables with direct routes.
            protocol direct DIRECT {
                ${optionalString (cfg.interfaces != []) "# "}disabled;
                check link on;
                ipv4;
                ipv6;

                interface ${directInterfaces};
            }
          '')
        ]
        ++ optional (cfg.peers != {}) (
          let
            peerFunc = import ./peer_config.nix;

            mkPeersFuncArgs = (
              x:
                args
                // {
                  inherit withType;
                }
                // {
                  peer =
                    {
                      peerName = x;
                    }
                    // peers.${x};
                }
            );

            mkPeerConfig = x: ''

              # ${x}
              ${peerFunc (mkPeersFuncArgs x)}

            '';
          in
            mkOrder 50 ''
                     # Nix-OS Generated for ${name}

              protocol static STATIC6 {
                  ipv6;
                  ${indentedLines 4 (concatStringsSep "\n" (map (x: "route ${x};") cfg.static6))}
              }

                     ${lib.concatMapStringsSep "\n" mkPeerConfig (builtins.attrNames peers)}
            ''
        )
      );
    };

    kittenModules.loopback0 = mkIf (cfg.loopback4 != null || cfg.loopback6 != null) {
      enable = mkDefault true;

      ipv4 = mkIf (cfg.loopback4 != null) [cfg.loopback4];
      ipv6 = mkIf (cfg.loopback6 != null) [cfg.loopback6];
    };

    # kittenModules.bird = {
    #   peers = filterAttrs (n: v: v ? template && v.template == "rrserver")
    #     srvCfg.peers;
    #   loopback4 = if (srvCfg ? loopback4 && srvCfg.loopback4 != null) then
    #     srvCfg.loopback4
    #   else
    #     null;
    #   loopback6 = if (srvCfg ? loopback6 && srvCfg.loopback6 != null) then
    #     srvCfg.loopback6
    #   else
    #     null;
    #   transitInterface =
    #     if (srvCfg ? transitInterface) then srvCfg.transitInterface else null;
    #   static6 = if (srvCfg ? static6 && builtins.typeOf srvCfg.static6 == "list"
    #     && srvCfg.static6 != [ ]) then
    #     srvCfg.static6
    #   else
    #     [ ];
    # };
  };
}
