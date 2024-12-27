{
  lib,
  config,
  target,
  targetConfig,
  birdFuncs,
  ...
}:
let
  inherit (lib) mkMerge mkOrder;
in
{
  services.bird2.config = mkMerge [
    (mkOrder 10 ''

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
          2a13:79c0:ff00::/40,
          2a13:79c0:ff00::/48+, # Special case for Toinux home
          # 2a13:79c0:ffff:fefe::/64{128,128},
          # 2a13:79c0:ffff:feff::/64{112,112},
          2a13:79c0:ffff::/48{48,64},
          2a13:79c0:fffe::/48{56,56}
        ];
      }
    '')
    (mkOrder 30 ''
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
    '')
  ];
}
