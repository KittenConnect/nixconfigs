{ lib, kittenLib, ... }:
let
  iface = "ens18";
  # kittenIFACE = "ens19";
in
{
  kittenModules = {
    bird.transitInterfaces = [ iface ];
    vrfs.tables.DN42.address = [
      "${kittenLib.network.dn42.dns6}/128"
      "${kittenLib.network.dn42.dns4}/32"
    ];

    firewall.forward.natRules = ''
      oifname "${iface}" ip6 saddr ${kittenLib.network.internal6.cafe.kittens.underlay.net} snat ip6 prefix to 2a12:5844:1311:feff::/64
      oifname "${iface}" ip6 saddr ${kittenLib.network.internal6.cafe.kittens.loopbacks.net} snat ip6 prefix to 2a12:5844:1311:fefe::/64
    '';
  };

  networking = {
    #nameservers = [ "1.3.3.7" ];
    interfaces = {
      "${iface}" = {
        ipv4.addresses = [
          {
            address = "185.10.17.235";
            prefixLength = 24;
          }
        ];

        ipv6.addresses = [
          {
            address = "2a07:8dc0:19:1f6::1";
            prefixLength = 128;
          }
        ];
      };
    };
    defaultGateway = {
      address = "185.10.17.254";
      metric = 42;
      interface = iface;
    };
    defaultGateway6 = {
      address = "fe80::1";
      metric = 42;
      interface = iface;
    };
    useDHCP = false;
    #dhcpcd.enable = false;
  };

  systemd.network.enable = true;
}
