{...}: let
  iface = "ens18";
  kittenIFACE = "ens19";
in {
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  networking = {
    #nameservers = [ "1.3.3.7" ];
    interfaces = {
      "${iface}".useDHCP = true;

      "${kittenIFACE}" = {
        # ipv4.addresses = [
        #   {
        #     address = "1.2.3.4";
        #     prefixLength = 24;
        #   }
        # ];

        ipv6.addresses = [
          {
            address = "1010:cafe:ffff:feff:b00b:3965:113:91";
            prefixLength = 112;
          }
        ];
      };
    };

    defaultGateway6 = {
      address = "1010:cafe:ffff:feff:b00b:3965:113:25";
      metric = 42;
      interface = kittenIFACE;
    };

    useDHCP = false;
    #dhcpcd.enable = false;
  };

  systemd.network.enable = true;
}
