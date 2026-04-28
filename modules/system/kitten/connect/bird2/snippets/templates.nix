{...}: let
  defaultMED = 2147483648; # 2^31
in {
  kittenModules.bird.extraConfigs."common/templates.conf" = {
    order = 10;

    text = ''
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

        vpn4 mpls { table vpntab4; import all; export all; extended next hop; };
        vpn6 mpls { table vpntab6; import all; export all; };
      }

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
                      bgp_med = bgp_med + ${builtins.toString defaultMED};
                else {
                      bgp_med = ${builtins.toString defaultMED};
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
                      bgp_med = bgp_med + ${builtins.toString defaultMED};
                else {
                      bgp_med = ${builtins.toString defaultMED};
                }
              accept;
            } else reject;
          };

          export filter { if is_valid6_network() && source ~ [RTS_STATIC, RTS_DEVICE, RTS_BGP, RTS_OSPF] then accept; else reject; };
          import limit 1000 action block;
        };

        ipv4 mpls {
          next hop self;
          extended next hop;

          import all;
          export all;
        };

        ipv6 mpls {
          next hop self;

          import all;
          export all;
        };

        mpls {
          label policy aggregate;
        };
      }

      template bgp dn42 {
        # metric is the number of hops between us and the peer
        path metric 1;
        ipv4 {
          extended next hop;
          import limit 9000 action block;
          import filter {
            if is_valid4_dn42_network() then {
              if defined( bgp_med ) then
                  bgp_med = bgp_med + ${builtins.toString defaultMED};
                else {
                  bgp_med = ${builtins.toString defaultMED};
                }
              accept;
            } else reject;
          };
          export filter { if is_valid4_dn42_network() && source ~ [RTS_STATIC, RTS_DEVICE] then accept; else reject; }; # TODO: proper filter + transit
          import table;
          table t4_DN42;
        };

        ipv6 {
          import limit 9000 action block;
          import filter {
            if is_valid6_dn42_network() then {
              if defined( bgp_med ) then
                  bgp_med = bgp_med + ${builtins.toString defaultMED};
                else {
                  bgp_med = ${builtins.toString defaultMED};
                }
              accept;
            } else reject;
          };
          export filter { if is_valid6_dn42_network() && source ~ [RTS_STATIC, RTS_DEVICE] then accept; else reject; };  # TODO: proper filter + transit
          import table;
          table t6_DN42;
        };
      }
    '';
  };
}
