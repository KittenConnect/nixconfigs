args@{
  lib,
  kittenLib,
  configHome, # Bird
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    types
    ;

  inherit (kittenLib.types) fileType;

  serviceName = if lib.versionOlder lib.version "25.05" then "bird2" else "bird";

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

  # Options

  birdFilterSubmodule =
    peerConfig: direction:
    {
      name,
      config,
      ...
    }:
    {
      options = {
        name = mkOption {
          type = types.str;
          default = peerConfig.peerName;
          readOnly = true;
        };
        ranges = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };
        allowed = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };
        prepend = mkOption {
          type = types.int;
          default = 0;
        };
        prependASN = mkOption {
          type = types.nullOr types.int;
          default = null;
        };
        bgpMED = mkOption {
          type = with types; nullOr (either int str);
          default = peerConfig.bgpMED;
        };
        direction = mkOption {
          type = types.enum [
            "import"
            "export"
          ];
          default = direction;
          readOnly = true;
        };
      };
      config = {
        allowed = lib.optional (
          config.ranges != [ ]
        ) "net ~ [ ${lib.concatStringsSep ", " config.ranges} ]";
      }
      // (lib.optionalAttrs (peer.template == "kittunderlay") {
        ipv4.bgpImports = lib.mkDefault { allowed = ["is_valid4_network()"]; };
        ipv6.bgpImports = lib.mkDefault { allowed = ["is_valid6_network()"]; };
      });
    };

  birdPeerSubmodule =
    {
      name,
      config,
      ...
    }:
    {
      options = {
        enable = mkEnableOption "${name} peer." // {
          default = true;
          example = false;
        };

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
          type = types.nullOr types.str;
          default = null;
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
          type = types.nullOr types.str;
          default = null;
          description = "bird template to use";
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
          bgpImports = mkOption {
            type =
              with types;
              nullOr (oneOf [
                str
                (submodule (birdFilterSubmodule config "import"))
                (listOf str)
              ]);
            default = [ ];
            description = "List of IPv4 import rules.";
          };

          bgpExports = mkOption {
            type =
              with types;
              nullOr (oneOf [
                str
                (submodule (birdFilterSubmodule config "export"))
                (listOf str)
              ]);
            default = [ ];
            description = "List of IPv4 export rules.";
          };
        };

        ipv6 = {
          bgpImports = mkOption {
            type =
              with types;
              nullOr (oneOf [
                str
                (submodule (birdFilterSubmodule config "import"))
                (listOf str)
              ]);
            default = [ ];
            description = "List of IPv6 import rules.";
          };

          bgpExports = mkOption {
            type =
              with types;
              nullOr (oneOf [
                str
                (submodule (birdFilterSubmodule config "export"))
                (listOf str)
              ]);
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
in
{
  enable = mkEnableOption "Kitten Bird2 module";
  # defaultSnippet = (mkEnableOption "Kitten Bird2 default config") // { default = true; example = false; };

  serviceName = mkOption {
    type = types.str;
    default = serviceName;
    description = "Name of the services.<name> options to fill - defaults to correct name based on NixOS version";
  };

  peers = mkOption {
    default = { };
    type = with types; attrsOf (submodule birdPeerSubmodule); # types.submodule (mkNamedOptionModule birdPeerSubmodule);
    description = "Configuration for BGP peers.";
  };

  extraConfigs = mkOption {
    type =
      (import ../../../../../lib/file-type.nix args).fileType "kittenModules.bird.extraConfigs" configHome
        {
          order = mkOption {
            type = with types; nullOr int;
            default = null;
          };
        };
    default = { };
    description = ''
      Attribute set of files to link into the bird's configuration directory.
      And include in bird.conf
    '';
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
    default = serviceName;
    description = "User to run process / own configurations";
  };

  static6 = mkOption {
    type = types.listOf types.str;
    default = [ ];
    description = "List of static IPv6 addresses.";
  };
}
