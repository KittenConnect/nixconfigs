{kittenLib, ...}: {
  networking = {
    #nameservers = [ "1.3.3.7" ];

    interfaces = {
      ens18.useDHCP = true;

      ens19 = {
        ipv6 = {
          routes = [
            {
              address = "2a13:79c0:ff00::";
              prefixLength = 40;
              via = "${kittenLib.network.internal6.cafe.kittens.underlay.routed.aure}:25";
            }
          ];
          addresses = [
            {
              address = "${kittenLib.network.internal6.cafe.kittens.underlay.routed.aure}:96";
              prefixLength = 112;
            }
          ];
        };
      };
    };

    useDHCP = false;
    useNetworkd = true;
    #dhcpcd.enable = false;
  };

  systemd.network.enable = true;
}
