{kittenLib, ...}: {
  kittenModules.vrfs = {
    enable = true;
    tables = {
      "SFR" = {
        tableID = 1010;
      };

      "ORANGE" = {
        tableID = 1020;
      };
    };
  };

  systemd.network.enable = true;
  systemd.network.networks = {
    "20-eth0" = {
      matchConfig = {
        Name = "eth0";
      };
      vrf = ["SFR"];

      networkConfig = {
        IPv6AcceptRA = true;
        LinkLocalAddressing = "ipv6";
      };
      DHCP = "ipv4";
    };
  };

  # Pick only one of the below networking options.
  networking = {
    interfaces = {
      ens18.useDHCP = true;

      # vlanXX = {

      #   # ipv4.addresses = [
      #   #   {
      #   #     address = "xxx.xx.xx.xx";
      #   #     prefixLength = 24;
      #   #   }
      #   # ];

      #   # ipv6.addresses = [
      #   #   {
      #   #     address = "1010:cafe:ffff:feff:b00b::xxx";
      #   #     prefixLength = 112;
      #   #   }
      #   # ];
      # };
    };

    # defaultGateway = {
    #   address = "xx.xx.xx.xx";
    #   metric = 42;
    #   interface = iface;
    # };

    # defaultGateway6 = {
    #   address = "fe80::1";
    #   metric = 42;
    #   interface = iface;
    # };

    useDHCP = false;
  };
}
