{kittenLib, lib, ...}: let
  iface = "ens18";
  kittenIFACE = "ens19";

  myRange = kittenLib.network.internal6.cafe.kittens.underlay.routed.iguane;
in {
  kittenModules.k3s.flannelIface = lib.mkForce kittenIFACE;

  networking = {
    interfaces = {
      "${iface}".useDHCP = true;

      "${kittenIFACE}" = {
        ipv4.addresses = [
          {
            address = "100.100.91.201";
            prefixLength = 24;
          }
        ];
        ipv6.addresses = [
          {
            address = myRange "201";
            prefixLength = 112;
          }
        ];
      };
    };

    defaultGateway6 = {
      address = "${myRange}:25";
      metric = 42;
      interface = kittenIFACE;
    };

    useDHCP = false;
  };

  systemd.network.enable = true;
}
