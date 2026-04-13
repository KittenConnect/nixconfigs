{...}: {
  kittenModules.bird.extraConfigs."common/templates.conf" = {
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
    '';
  };
}
