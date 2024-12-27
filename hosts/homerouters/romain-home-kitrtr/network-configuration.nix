{ ... }:
{
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  networking = {
    #nameservers = [ "1.3.3.7" ];

    vlans = {
      vlan36 = {
        id = 36;
        interface = "ens19";
      };
    };

    interfaces = {
      ens18.useDHCP = true;

      vlan36 = {

        # ipv4.addresses = [
        #   {
        #     address = "185.10.17.209";
        #     prefixLength = 24;
        #   }
        # ];

        ipv6.addresses = [
          {
            address = "2a13:79c0:ffff:feff:b00b:3615:1:6969";
            prefixLength = 112;
          }
        ];
      };
    };

    # defaultGateway = {
    #   address = "185.10.17.254";
    #   metric = 42;
    #   interface = iface;
    # };

    # defaultGateway6 = {
    #   address = "fe80::1";
    #   metric = 42;
    #   interface = iface;
    # };

    useDHCP = false;
    #dhcpcd.enable = false;
  };

  systemd.network.enable = true;
}
