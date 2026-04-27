{kittenLib, ...}: {
  kittenModules.bird.extraConfigs."common/functions.conf" = {
    order = 05;

    text = ''
      function update_latency(int link_latency) {
          bgp_community.add((64511, link_latency));
              if (64511, 9) ~ bgp_community then { bgp_community.delete([(64511, 1..8)]); return 9; }
          else if (64511, 8) ~ bgp_community then { bgp_community.delete([(64511, 1..7)]); return 8; }
          else if (64511, 7) ~ bgp_community then { bgp_community.delete([(64511, 1..6)]); return 7; }
          else if (64511, 6) ~ bgp_community then { bgp_community.delete([(64511, 1..5)]); return 6; }
          else if (64511, 5) ~ bgp_community then { bgp_community.delete([(64511, 1..4)]); return 5; }
          else if (64511, 4) ~ bgp_community then { bgp_community.delete([(64511, 1..3)]); return 4; }
          else if (64511, 3) ~ bgp_community then { bgp_community.delete([(64511, 1..2)]); return 3; }
          else if (64511, 2) ~ bgp_community then { bgp_community.delete([(64511, 1..1)]); return 2; }
          else return 1;
      }

      function update_bandwidth(int link_bandwidth)
      int local_bandwidth ; {
          if link_bandwidth > BANDWIDTH then local_bandwidth = BANDWIDTH;
          else local_bandwidth = link_bandwidth;

          bgp_community.add((64511, local_bandwidth));
              if (64511, 21) ~ bgp_community then { bgp_community.delete([(64511, 22..29)]); return 21; }
          else if (64511, 22) ~ bgp_community then { bgp_community.delete([(64511, 23..29)]); return 22; }
          else if (64511, 23) ~ bgp_community then { bgp_community.delete([(64511, 24..29)]); return 23; }
          else if (64511, 24) ~ bgp_community then { bgp_community.delete([(64511, 25..29)]); return 24; }
          else if (64511, 25) ~ bgp_community then { bgp_community.delete([(64511, 26..29)]); return 25; }
          else if (64511, 26) ~ bgp_community then { bgp_community.delete([(64511, 27..29)]); return 26; }
          else if (64511, 27) ~ bgp_community then { bgp_community.delete([(64511, 28..29)]); return 27; }
          else if (64511, 28) ~ bgp_community then { bgp_community.delete([(64511, 29..29)]); return 28; }
          else return 29;
      }

      function update_crypto(int link_crypto) {
          bgp_community.add((64511, link_crypto));
              if (64511, 31) ~ bgp_community then { bgp_community.delete([(64511, 32..34)]); return 31; }
          else if (64511, 32) ~ bgp_community then { bgp_community.delete([(64511, 33..34)]); return 32; }
          else if (64511, 33) ~ bgp_community then { bgp_community.delete([(64511, 34..34)]); return 33; }
          else return 34;
      }

      function update_flags(int link_latency; int link_bandwidth; int link_crypto)
      {
          update_latency(link_latency);
          update_bandwidth(link_bandwidth);
          update_crypto(link_crypto);
          return true;
      }

      function update_route_origin(int region; int country)
      {
          bgp_community.add((64511, region));
          bgp_community.add((64511, country));
      }


      function is_valid4_network() {
          return net ~ [
            172.23.193.192/26,
            172.23.193.192/26{32,32}
          ];
      }

      function is_valid6_network() {
          return net ~ [
            ${kittenLib.network.internal6.cafe.kittens.net}{48,64},
            ${kittenLib.network.internal6.cafe.kittens.loopbacks.net}{128,128},
            ${kittenLib.network.internal6.cafe.kittens.underlay.net}{112,112},
            2a12:5844:1310::/44
          ];
      }

      function is_rr_valid6_network() {
          return net ~ [
            ${kittenLib.network.internal6.cafe.kittens.net}{48,64},
            ${kittenLib.network.internal6.cafe.customers.net}{56,56},
            2a12:5844:1310::/44
          ];
      }
    '';
  };
}
