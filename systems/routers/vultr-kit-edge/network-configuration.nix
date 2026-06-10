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
    vrfs.tables.DN42.address = [
      "${kittenLib.network.dn42.dns6}/128"
      "${kittenLib.network.dn42.dns4}/32"
    ];
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
