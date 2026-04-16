{kittenLib, ...}: {
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
