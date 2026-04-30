{kittenLib, ...}: let mgmtIface = "ens18"; homeIface = "ens19"; upIface = "ens20"; in {
  kittenModules.vrfs.enable = true;
  kittenModules.bird.vrfs = {
    "SFR" = {
      tableID = 1010;
      ipv6.enable = false;
      ipv4 = {
        enable = true;
        bgpExports = {
          ranges = ["100.100.91.0/24"];
        };
      };
    };

    "ORANGE" = {
      tableID = 1020;
      ipv6.enable = false;
      ipv4 = {
        enable = true;
        bgpExports = {
          ranges = ["100.100.91.0/24"];
        };
      };
    };

    "DN42" = { # Already exists - only add static range
      ipv6.static = [
        "fd42:7331:1241::/48 unreachable"
      ];
    };
  };

  systemd.network.enable = true;
  systemd.network.networks = {
    "40-vlan666" = {
      matchConfig = {
        Name = "vlan666";
      };
      vrf = ["SFR"];

      networkConfig = {
        IPv6AcceptRA = true;
        LinkLocalAddressing = "ipv6";
      };
      DHCP = "ipv4";
    };

    "40-vlan777" = {
      matchConfig = {
        Name = "vlan777";
      };
      vrf = ["ORANGE"];

      networkConfig = {
        IPv6AcceptRA = true;
        LinkLocalAddressing = "ipv6";
      };
      DHCP = "ipv4";
    };

    "40-vlan91" = {
      address = [
        "100.100.91.25/24"
        "1010:cafe:ffff:feff:b00b:3945:a51:25/112"
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
    vlans = {
      vlan91 = {
        id = 91;
        interface = homeIface;
      };
      
      vlan666 = {
        id = 666;
        interface = upIface;
      };
      vlan777 = {
        id = 777;
        interface = upIface;
      };
    };

    interfaces = {
      ${mgmtIface} = {
        ipv4.addresses = [{
          address = "10.10.50.25";
          prefixLength = 24;
        }];

        ipv4.routes = [{
          address = "10.10.0.0";
          prefixLength = 16;
          via = "10.10.50.1";
        }];
      };

      vlan91 = {

        # ipv4.addresses = [
        #   {
        #     address = "xxx.xx.xx.xx";
        #     prefixLength = 24;
        #   }
        # ];

        # ipv6.addresses = [
        #   {
        #     address = "1010:cafe:ffff:feff:b00b:3945:a51:25";
        #     prefixLength = 112;
        #   }
        # ];
      };
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
