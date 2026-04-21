args @ {
  lib,
  kittenLib,
  pkgs,
  config,
  options,
  name,
  ...
}: let
  inherit
    (lib)
    optional
    optionalString
    mkOrder
    mkDefault
    attrNames
    filterAttrs
    concatStringsSep
    concatMapStringsSep
    mkMerge
    mkIf
    unique
    mapAttrsToList
    ;

  inherit (kittenLib.strings) indentedLines quotedString;

  # Main config is here
  cfg = config.kittenModules.bird;
  configHome = "bird";

  # Values
  peers = cfg.peers;
  peersRouteReflectors = attrNames (filterAttrs (n: v: v.template == "rrserver") peers);

  sortedExtraConfigs = builtins.sort (
    p: q:
      if (p.value.order or null) != null && (q.value.order or null) != null
      then builtins.lessThan (p.value.order) (q.value.order)
      else if (p.value.order or null) == null && (q.value.order or null) == null
      then builtins.lessThan p.name q.name
      else p.value.order != null
  ) (lib.attrsToList cfg.extraConfigs);

  directInterfaces = let
    noLoopback = builtins.elem "-lo" cfg.interfaces;
  in
    if (cfg.interfaces != null)
    then
      lib.concatMapStringsSep ", " quotedString (
        (optional (!noLoopback && config.kittenModules.loopback0.enable) "lo")
        ++ cfg.interfaces
        ++ (optional (builtins.all (lib.hasPrefix "-") cfg.interfaces) "*") # TODO: assert no "*"
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
    ./autoMED
  ];

  # Options
  options.kittenModules.bird = import ./options.nix (args // {inherit configHome;});

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

    environment.etc = let
      etcType = options.environment.etc.type.nestedTypes.elemType.getSubOptions [];
      sane = lib.filterAttrs (n: v: builtins.hasAttr n etcType);
    in
      lib.mapAttrs' (name: file: lib.nameValuePair "${configHome}/${name}" (sane file)) cfg.extraConfigs;

    # Service configuration
    services.${cfg.serviceName} =
      (lib.optionalAttrs (cfg.serviceName != "bird2") {
        package = pkgs.bird2;
      })
      // {
        enable = cfg.enable;

        preCheckConfig = let
          configDir = pkgs.linkFarm "bird-directory" (lib.mapAttrs (n: v: v.source) cfg.extraConfigs);
          getIncludes = lib.optionalAttrs (
            cfg.extraConfigs != {}
          ) "${pkgs.rsync}/bin/rsync -arvp ${configDir}/ ./";
        in ''
          if grep -q include ${cfg.serviceName}.conf; then
            echo "Found the following includes in bird configuration" >&2
            grep include ${cfg.serviceName}.conf >&2
          fi

          ${getIncludes}
        '';

        config = mkMerge [
          (mkOrder 0 ''
            log syslog all;

            # Nix-OS router config generated for ${name}

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

            protocol static STATIC6 {
              ipv6;
            ${indentedLines 1 (concatStringsSep "\n" (map (x: "route ${x};") cfg.static6))}
            }
          '')

          (mkOrder 10 ''
            # NixOS declared includes
            ${concatMapStringsSep "\n" (
                x: ''${optionalString (!(cfg.enable)) "# "}include "${x.name}";''
              )
              sortedExtraConfigs}
          '')
        ];
      };

    kittenModules.bird.extraConfigs = let
      peerFunc = import ./peer_config.nix;

      mkPeersFuncArgs = (
        peerName: peerConfig:
          args
          // {
            peer =
              {
                inherit peerName;
              }
              // peerConfig;
          }
      );
    in
      lib.mapAttrs' (
        n: v:
          lib.nameValuePair "peers/${n}.conf" {
            # inherit (v) enable;
            text = ''
              # ${n}
              ${peerFunc (mkPeersFuncArgs n v)}
            '';
          }
      )
      peers;

    kittenModules.loopback0 = mkIf (cfg.loopback4 != null || cfg.loopback6 != null) {
      enable = mkDefault true;

      ipv4 = mkIf (cfg.loopback4 != null) [cfg.loopback4];
      ipv6 = mkIf (cfg.loopback6 != null) [cfg.loopback6];
    };

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
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
