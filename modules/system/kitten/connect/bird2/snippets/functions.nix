{kittenLib, ...}: {
  kittenModules.bird.extraConfigs."common/functions.conf" = {
    order = 05;

    text = ''
      function update_med(int link_latency_in_microsec) {
        if (link_latency_in_microsec > 0 && link_latency_in_microsec < 2147483647) then {
          if (defined(bgp_med)) then {
            bgp_med = bgp_med + link_latency_in_microsec;
          } else {
            bgp_med = link_latency_in_microsec;
          }
        }
      }

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

      function update_bandwidth(int link_bandwidth) {
        # int local_bandwidth ; 
        # if link_bandwidth > BANDWIDTH then local_bandwidth = BANDWIDTH;
        # else local_bandwidth = link_bandwidth;
        bgp_community.add((64511, link_bandwidth));

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

      function med2latency() {
        int latency_community;

        if (defined(bgp_med) && bgp_med > 0) then { # require correct MED
          # thresholds converted: ms * 1000 = µs
              if (bgp_med <= 2700) then latency_community = 1;
          else if (bgp_med <= 7300) then latency_community = 2;
          else if (bgp_med <= 20000) then latency_community = 3;
          else if (bgp_med <= 55000) then latency_community = 4;
          else if (bgp_med <= 148000) then latency_community = 5;
          else if (bgp_med <= 403000) then latency_community = 6;
          else if (bgp_med <= 1097000) then latency_community = 7;
          else if (bgp_med <= 2981000) then latency_community = 8;
          else latency_community = 9; # defaults to high latency

          update_latency(latency_community);
        }
      }

      function update_crypto(int link_crypto) {
        bgp_community.add((64511, link_crypto));

            if (64511, 31) ~ bgp_community then { bgp_community.delete([(64511, 32..34)]); return 31; }
        else if (64511, 32) ~ bgp_community then { bgp_community.delete([(64511, 33..34)]); return 32; }
        else if (64511, 33) ~ bgp_community then { bgp_community.delete([(64511, 34..34)]); return 33; }
        else return 34;
      }

      function update_flags(int link_latency; int link_bandwidth; int link_crypto) {
        update_latency(link_latency);
        update_bandwidth(link_bandwidth);
        update_crypto(link_crypto);
        return true;
      }

      function update_route_origin(int region; int country) {
        bgp_community.add((64511, region));
        bgp_community.add((64511, country));
      }

    function is_valid4_dn42_network() {
      return net ~ [
        172.20.0.0/14{21,29}, # dn42
        172.20.0.0/24{28,32}, # dn42 Anycast
        172.21.0.0/24{28,32}, # dn42 Anycast
        172.22.0.0/24{28,32}, # dn42 Anycast
        172.23.0.0/24{28,32}, # dn42 Anycast
        172.31.0.0/16+,       # ChaosVPN
        10.100.0.0/14+,       # ChaosVPN
        10.127.0.0/16{16,32}, # neonetwork
        10.0.0.0/8{15,24}     # Freifunk.net
      ];
    }

    function is_valid6_dn42_network() {
      return net ~ [
        fd00::/8{44,64} # ULA address space as per RFC 4193
      ];
    }

      function is_kitten4_network() {
        return net ~ [
          172.23.193.192/26,
          172.23.193.192/26{32,32}
        ];
      }

      function is_kitten6_network() {
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
