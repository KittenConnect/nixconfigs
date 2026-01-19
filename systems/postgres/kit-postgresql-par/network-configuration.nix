{ ... }:
let
  kittenIface = "ens18";
in
{
  networking = {
    nameservers = [ "2620:fe::fe" ];

    interfaces = {
      # ens18.useDHCP = true;

      ens19 = {
        ipv4 = {
          addresses = [
            {
              address = "10.200.2.110";
              prefixLength = 24;
            }
          ];
        };
      };

      ${kittenIface} = {
        ipv6 = {
          routes = [
            {
              address = "2a13:79c0:ff00::";
              prefixLength = 40;
              via = "2a13:79c0:ffff:feff:b00b:3615:1:6969";
            }
          ];
          addresses = [
            {
              address = "2a13:79c0:ffff:feff:b00b:3615:1:907";
              prefixLength = 112;
            }
          ];
        };
      };
    };

    defaultGateway6 = {
      address = "2a13:79c0:ffff:feff:b00b:3615:1:6969";
      metric = 42;
      interface = kittenIface;
    };

    useDHCP = false;
    useNetworkd = true;
    #dhcpcd.enable = false;
  };

  systemd.network.enable = true;
}
