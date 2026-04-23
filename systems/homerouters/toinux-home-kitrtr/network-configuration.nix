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
    "20-eth1" = {
      matchConfig = {
        Name = "eth1";
      };
      vrf = ["SFR"];

      networkConfig = {
        IPv6AcceptRA = true;
        LinkLocalAddressing = "ipv6";
      };
      DHCP = "ipv4";
    };

    "20-eth2" = {
      matchConfig = {
        Name = "eth2";
      };
      vrf = ["ORANGE"];

      networkConfig = {
        IPv6AcceptRA = true;
        LinkLocalAddressing = "ipv6";
      };
      DHCP = "ipv4";
    };

    "50-eth3" = {
      matchConfig = {
        Name = "eth3";
      };

      address = [
        "100.100.91.10/24"
        "2a13:79c0:ffff:feff:b00b:3945:a51:10/112"
      ];

      networkConfig = {
        IPv6AcceptRA = false;
        LinkLocalAddressing = "ipv6";
      };
      DHCP = "no";
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
