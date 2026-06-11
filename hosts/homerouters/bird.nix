{
  lib,
  config,
  target,
  targetConfig,
  ...
}:
let
  inherit (lib)
    optional
    optionals
    optionalString
    mkOrder
    attrNames
    filterAttrs
    concatStringsSep
    concatMapStringsSep
    ;

  birdCfg = config.services.bird2;

  srvCfg =
    let
      cfg =
        if targetConfig ? birdConfig then
          targetConfig.birdConfig
        else
          let
            p = (./. + "/${target}/birdconfig.nix");
          in
          if builtins.pathExists p then (import p { inherit targetConfig; }) else { };
    in
    if cfg ? peers then
      cfg
    else
      let
        peers = (import (./. + "/${target}/peers/") { });
      in
      (cfg // { inherit peers; });

  rrs = attrNames (filterAttrs (n: v: v ? template && v.template == "rrserver") srvCfg.peers);

  lo4 =
    if (srvCfg ? loopback4 && srvCfg.loopback4 != null && srvCfg.loopback4 != "") then
      srvCfg.loopback4
    else
      null;

  lo6 =
    if (srvCfg ? loopback6 && srvCfg.loopback6 != null && srvCfg.loopback6 != "") then
      srvCfg.loopback6
    else
      null;
in
{
  imports = [
    ./bird_peers.nix
    # ./bird_statics.nix 
  ];

  config = {

    sops.templates."bird_secrets.conf" = {
      owner = "bird2";
    };

    _module.args = {
      birdConfig = srvCfg;
    };

    networking.firewall.allowedTCPPorts = [
      179 # BGP
      1790 # Internal BGP
    ];

    networking.interfaces.lo = {
      ipv4.addresses =
        lib.mkIf
          (
            lo4 != null && config.customModules.loopback0.ipv4 == [ ] || !config.customModules.loopback0.enable
          )
          [
            {
              address = "${toString srvCfg.loopback4}";
              prefixLength = 32;
            }
          ];
      ipv6.addresses =
        lib.mkIf
          (
            lo6 != null && config.customModules.loopback0.ipv6 == [ ] || !config.customModules.loopback0.enable
          )
          [
            {
              address = "${toString srvCfg.loopback6}";
              prefixLength = 128;
            }
          ];
    };

    services.bird2.preCheckConfig = ''
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

    services.bird2.config = mkOrder 0 (
      concatStringsSep "\n\n" (
        let
          transitIFACE = if srvCfg ? transitInterface then srvCfg.transitInterface else null;

          quoteString = x: ''"${x}"'';
        in
        [
          "log syslog all;"

          ''include "${config.sops.templates."bird_secrets.conf".path}";''

          ''
            # The Device protocol is not a real routing protocol. It does not generate any
            # routes and it only serves as a module for getting information about network
            # interfaces from the kernel. It is necessary in almost any configuration.
            protocol device DEV {}

            # The direct protocol is not a real routing protocol. It automatically generates
            # direct routes to all network interfaces. Can exist in as many instances as you
            # wish if you want to populate multiple routing tables with direct routes.
            protocol direct DIRECT {
                #disabled;
                check link on;
                ipv4;
                ipv6;
                interface "*";
            }
          ''

          ''
            #<== Générique
            function is_valid4_network() {
              return net ~ [
                172.23.193.192/26,
                172.23.193.192/26{32,32}
              ];
            }

            function is_valid6_network() {
              return net ~ [
                2a13:79c0:ff00::/40,
                2a13:79c0:ffff::/48{48,64},
                2a13:79c0:ffff:fefe::/64{128,128},
                2a13:79c0:ffff:feff::/64{112,112}
              ];
            }


            function is_rr_valid6_network() {
              return net ~ [
                ${
                  optionalString (transitIFACE != null) "::/0,"
                } # Announce (or not) default route [transitInterface = ${toString transitIFACE}]
                2a13:79c0:ff00::/40,
                2a13:79c0:ff00::/48+, # Special case for Toinux home
                # 2a13:79c0:ffff:fefe::/64{128,128},
                # 2a13:79c0:ffff:feff::/64{112,112},
                2a13:79c0:ffff::/48{48,64},
                2a13:79c0:fffe::/48{56,56}
              ];
            }

          ''

          ''
            # The Kernel protocol is not a real routing protocol. Instead of communicating
            # with other routers in the network, it performs synchronization of BIRD
            # routing tables with the OS kernel. One instance per table.
            protocol kernel KERNEL4 {
            	ipv4 {                  # Connect protocol to IPv4 table by channel
            #             table master4;    # Default IPv4 table is master4
            #             import all;       # Import to table, default is import all
            #             export all;       # Export to protocol. default is export none
            	      export filter {
            		  if  ( is_valid4_network() || source ~ [RTS_STATIC] || proto ~ "(${concatStringsSep "|" rrs})"
                    ) then {
                      ${
                        optionalString (lo4 != null) ''
                          if source ~ [RTS_BGP] || net ~ [ 0.0.0.0/0 ] then {
                            krt_prefsrc=${lo4};
                          }
                        ''
                      }
            		     accept;
            		  } else reject;
            	      };
            	};
              merge paths on;
            #       learn;                  # Learn alien routes from the kernel
            #       kernel table 10;        # Kernel table to synchronize with (default: main)
            }

            # Another instance for IPv6, skipping default options
            protocol kernel KERNEL6 {
            #       ipv6 { export all; };
            	ipv6 {
            	     export filter {
            		 if  ( is_valid6_network() || source ~ [RTS_STATIC] || proto ~ "(${concatStringsSep "|" rrs})" ) then {
                        ${
                          optionalString (lo6 != null) ''
                              if source ~ [RTS_BGP] || net ~ [ ::/0 ] then {
                            krt_prefsrc=${lo6};
                              }
                          ''
                        }
            		       accept;
            		 } else reject;
            	     };
            	};
              
              merge paths on;
            }
          ''

          ''

            template bgp rrserver {
              local port 1790;
              neighbor port 179;
              multihop 5;

              ipv4 {
                gateway recursive;
                extended next hop;
                next hop self;

                import filter { accept; };

                export none;
                # export filter { if is_v4_network() && source ~ [RTS_STATIC, RTS_DEVICE, RTS_BGP, RTS_OSPF] then accept; else reject; };
                import limit 1000 action block;
                igp table master4; # IGP table for routes with IPv4 nexthops
                #  igp table master6; # IGP table for routes with IPv4 nexthops
              };

              ipv6 {
                gateway recursive;
                next hop self;

                import filter { accept; };
                export filter { if is_rr_valid6_network() && source ~ [RTS_STATIC, RTS_DEVICE, RTS_BGP, RTS_OSPF] then accept; else reject; };
                import limit 1000 action block;
                igp table master6; # IGP table for routes with IPv6 nexthops
              };

            }
          ''

          ''
            template bgp kittunderlay {
            #  local as 4242421945;
            #  neighbor as kittenASN;
              local port 1790;
              neighbor port 1790;
              rr client;
              path metric off;
              ipv4 {
                extended next hop;
                next hop self;
                import keep filtered;

                import filter {
                  if is_valid4_network() then {
                    if defined( bgp_med ) then
                            bgp_med = bgp_med + 1000;
                      else {
                            bgp_med = 1000;
                      }
                    accept;
                  } else reject;
                };

                export filter { if is_valid4_network() && source ~ [RTS_STATIC, RTS_DEVICE, RTS_BGP, RTS_OSPF] then accept; else reject; };
                import limit 1000 action block;
              };

              ipv6 {
                next hop self;
                import keep filtered;

                import filter {
                  if is_valid6_network() then {
                    if defined( bgp_med ) then
                            bgp_med = bgp_med + 1000;
                      else {
                            bgp_med = 1000;
                      }
                    accept;
                  } else reject;
                };

                export filter { if is_valid6_network() && source ~ [RTS_STATIC, RTS_DEVICE, RTS_BGP, RTS_OSPF] then accept; else reject; };
                import limit 1000 action block;
              };

            }
          ''
        ]
        ++
          optionals (srvCfg ? static6 && builtins.typeOf srvCfg.static6 == "list" && srvCfg.static6 != [ ])
            [
              ''
                protocol static STATIC6 {
                    ipv6;
                ${concatStringsSep "\n" (map (x: "    " + "route ${x};") srvCfg.static6)}
                }
              ''
            ]
      )
    );
  };
}
