args@{ lib, pkgs, config, target, ... }:
let
  inherit (lib)
    optional optionals optionalString mkOrder mkDefault attrNames filterAttrs
    concatStringsSep concatMapStringsSep listToAttrs nameValuePair mkMerge mkIf
    mkOption mkEnableOption types unique mapAttrsToList isType;

  withType = types: x: lib.toFunction types.${builtins.typeOf x} x;

  quoteString = x: ''"${x}"'';

  # Main config is here
  birdCfg = config.services.bird2;
  cfg = config.customModules.bird;

  # Values
  peers = cfg.peers;
  peersWithPasswordRef = filterAttrs (n: v: v.passwordRef != null) peers;
  peersRouteReflectors =
    attrNames (filterAttrs (n: v: v.template == "rrserver") peers);

  passwords =
    unique (mapAttrsToList (n: v: v.passwordRef) peersWithPasswordRef);

  # Example
  # config.customModules.bird = {
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
        type = types.nullOr types.str;
        default = null;
        description = "Password for BGP session.";
      };

      passwordRef = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Reference to a password for BGP session.";
      };

      ipv4 = {

        imports = mkOption {
          type = types.nullOr types.oneOf types.str types.lambda
            (types.listOf types.str);
          default = [ ];
          description = "List of IPv4 import rules.";
        };

        exports = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "List of IPv4 export rules.";
        };

      };

      ipv6 = {

        imports = mkOption {
          type =
            types.nullOr (types.oneOf [ types.str (types.listOf types.str) ]);
          default = [ ];
          description = "List of IPv6 import rules.";
        };

        exports = mkOption {
          type = types.nullOr (types.oneOf [
            types.str
            # (types.functionTo {
            #   description = "return filter name / filter list dynamically";
            # })
            (types.listOf types.str)
          ]);
          # type = types.listOf types.str;
          default = [ ];
          description = "List of IPv6 export rules.";
        };

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
        default = if config.multihop == 0 then config.peerName else null;
        # default = if config.wireguard != { } then
        #   (if config.wireguard ? interface then
        #     config.wireguard.interface
        #   else
        #     config.peerName)
        # else
        #   null;
      };
    };
  };

in {

  imports = [ ./server_config.nix ];

  # Options
  options = {
    customModules.bird = {
      enable = mkEnableOption "Kitten Bird2 module";

      peers = mkOption {
        default = { };
        type = with types;
          attrsOf (submodule
            birdPeerSubmodule); # types.submodule (mkNamedOptionModule birdPeerSubmodule);
        description = "Configuration for BGP peers.";
      };

      loopback4 = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "IPv4 loopback address.";
      };

      loopback6 = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "IPv6 loopback address.";
      };

      interfaces = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "Interfaces to generate direct routes for.";
      };

      transitInterfaces = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Transit interface.";
      };

      user = mkOption {
        type = types.str;
        default = "bird2";
        description = "User to run process / own configurations";
      };

      static6 = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "List of static IPv6 addresses.";
      };
    };
  };

  # Implementation
  config = mkIf cfg.enable {
    _module.args = {
      birdConfig = cfg;
      birdFuncs = { inherit quoteString; };
    };

    # Firewalling
    networking.firewall.allowedTCPPorts = [
      179 # BGP
      1790 # Internal BGP
    ];

    # Secrets management
    sops = mkIf (passwords != [ ]) {
      secrets = (listToAttrs (map (n:
        nameValuePair "bird_secrets/${n}" {
          reloadUnits = [ "bird2.service" ];
        }) passwords));

      templates."bird_secrets.conf" = mkIf (passwords != [ ]) {
        owner = cfg.user;
        content = (mkMerge (map (password: ''
          define secretPassword_${password} = "${
            config.sops.placeholder."bird_secrets/${password}"
          }";
        '') passwords));
      };
    };

    # Service configuration
    services.bird2 = {
      preCheckConfig = mkIf (passwords != [ ]) ''
        echo "Bird configuration include these resources"
        grep include bird2.conf

        LINE=$(grep -n include bird2.conf | grep bird_secrets.conf | head -1 | cut -d: -f1)
        if [ ! -z "$LINE" ]; then
          echo "Found secrets importing, will substitute it with placeholders values"
          sed ''${LINE}d -i bird2.conf
          sed "$(($LINE))i"'include "_secrets_substitute.conf";' -i bird2.conf

          cat > _secrets_substitute.conf <<< '
            ${config.sops.templates."bird_secrets.conf".content}
          '

          # cat _secrets_substitute.conf bird2.conf
        fi
      '';

      config = mkMerge ([
        (mkOrder 0 ''
          log syslog all;


          # The Device protocol is not a real routing protocol. It does not generate any
          # routes and it only serves as a module for getting information about network
          # interfaces from the kernel. It is necessary in almost any configuration.
          protocol device DEV {}

        '')
      ] ++ optional (passwords != [ ]) (mkOrder 5
        ''include "${config.sops.templates."bird_secrets.conf".path}";'')
        ++ optional (cfg.peers != { }) (let
          peerFunc = (import ./peer_config.nix);

          mkPeersFuncArgs = (x:
            args // {
              inherit withType;
            } // {
              peer = { peerName = x; } // peers.${x};
            });

          mkPeerConfig = x: ''

            # ${x}
            ${peerFunc (mkPeersFuncArgs x)}

          '';

        in mkOrder 50 ''
          # Nix-OS Generated for ${target}
          ${lib.concatMapStringsSep "\n" mkPeerConfig
          (builtins.attrNames peers)}
        ''));
    };

    customModules.loopback0 =
      mkIf (cfg.loopback4 != null || cfg.loopback6 != null) {
        enable = mkDefault true;

        ipv4 = mkIf (cfg.loopback4 != null) [ cfg.loopback4 ];
        ipv6 = mkIf (cfg.loopback6 != null) [ cfg.loopback6 ];
      };

    # customModules.bird = {
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
