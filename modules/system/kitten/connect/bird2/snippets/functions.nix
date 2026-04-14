{...}: {
  kittenModules.bird.extraConfigs."common/functions.conf" = {
    order = 05;

    text = ''
      function is_valid4_network() {
          return net ~ [
            172.23.193.192/26,
            172.23.193.192/26{32,32}
          ];
      }

      function is_valid6_network() {
          return net ~ [
            2a12:5844:1310::/44,
            2a13:79c0:ffff::/48{48,64},
            1010:cafe:ffff:fefe::/64{128,128},
            1010:cafe:ffff:feff::/64{112,112}
          ];
      }

      function is_rr_valid6_network() {
          return net ~ [
            2a12:5844:1310::/44,
            # 1010:cafe:ffff:fefe::/64{128,128},
            # 1010:cafe:ffff:feff::/64{112,112},
            2a13:79c0:ffff::/48{48,64},
            2a13:79c0:fffe::/48{56,56}
          ];
      }
    '';
  };
}
