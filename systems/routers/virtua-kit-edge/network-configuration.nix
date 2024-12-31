{ ... }:
let
  iface = "ens18";
  # kittenIFACE = "ens19";
in
{
  kittenModules = {
    bird.transitInterfaces = [ iface ];
  };

  networking = {
    #nameservers = [ "1.3.3.7" ];
    interfaces = {
      "${iface}" = {
        ipv4.addresses = [
          {
            address = "185.10.17.209";
            prefixLength = 24;
          }
        ];

        ipv6.addresses = [
          {
            address = "2a07:8dc0:19:1cf::1";
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
