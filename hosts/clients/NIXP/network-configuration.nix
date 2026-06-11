{ ... }:
{
  networking = {
    #nameservers = [ "1.3.3.7" ];

    interfaces = {
      ens18.useDHCP = true;

      ens19 = {

        # ipv4.addresses = [
        #   {
        #     address = "185.10.17.209";
        #     prefixLength = 24;
        #   }
        # ];

        ipv6 = {
          routes = [
            {
              address = "2a13:79c0:ff00::";
              prefixLength = 40;
              via = "2a13:79c0:ffff:feff:b00b:caca:b173:25";
            }
          ];
          addresses = [
            {
              address = "2a13:79c0:ffff:feff:b00b:caca:b173:96";
              prefixLength = 112;
            }
          ];
        };
      };
    };

    # defaultGateway = {
    #   address = "185.10.17.254";
    #   metric = 42;
    #   interface = iface;
    # };

    # defaultGateway6 = {
    #   address = "2a13:79c0:ffff:feff:b00b:3965:113:25";
    #   metric = 42;
    #   interface = kittenIFACE;
    # };

    useDHCP = false;
    useNetworkd = true;
    #dhcpcd.enable = false;
  };

  systemd.network.enable = true;

}
