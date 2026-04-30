{ lib, kittenLib, ... }:
let
  iface = "enp1s0";
  # kittenIFACE = "ens19";
in
{
  kittenModules = {
    bird.transitInterfaces = [ iface ];
    bird.static6 = lib.mapAttrsToList (n: v: ''${n} via "fe80::${v}%${iface}"'') {
      "2001:19f0::/32" = "fc00:4ff:fe82:5c6e";
    };
    vrfs.requiredLink = iface;

    firewall.forward.natRules = ''
      oifname "${iface}" ip6 saddr ${kittenLib.network.internal6.cafe.kittens.underlay.net} snat ip6 prefix to 2a12:5844:1311:feff::/64
      oifname "${iface}" ip6 saddr ${kittenLib.network.internal6.cafe.kittens.loopbacks.net} snat ip6 prefix to 2a12:5844:1311:fefe::/64
    '';
  };

  networking = {
    #nameservers = [ "1.3.3.7" ];
    interfaces = {
      "${iface}" = {
        useDHCP = true;
        ipv6.addresses = [
          {
            address = "2001:19f0:6801:365::1";
            prefixLength = 128;
          }
        ];
      };
    };
    defaultGateway = {
      address = "140.82.54.1";
      metric = 42;
      interface = iface;
    };
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
