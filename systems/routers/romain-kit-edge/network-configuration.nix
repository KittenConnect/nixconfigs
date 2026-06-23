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
    nameservers = [ "2606:4700:4700::1:1001" ];
    interfaces = {
      "${iface}" = {
        ipv4.addresses = [
          {
            address = "5.178.107.124";
            prefixLength = 24;
          }
        ];

        ipv6.addresses = [
          {
            address = "2a0f:85c1:b60::1:1ef";
            prefixLength = 128;
          }
        ];
      };
    };
    defaultGateway = {
      address = "5.178.107.1";
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
