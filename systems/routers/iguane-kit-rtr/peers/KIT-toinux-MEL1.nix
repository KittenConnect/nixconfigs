{kittenLib, ...}: let
  kittenASN = 4242421945;
in {
  peerAS = kittenASN;
  # peerIP = kittenLib.network.internal6.cafe.kittens.underlay "3013";
  localAS = kittenASN;

  wireguard = {
    address = 12306;
    port = 51851;
    onIFACE = "ens18";

    peerKey = "xFNmHprArmxWD0W0YhD8nQZR1EbpXNWU8Rr5puSrDyw=";
  };

  template = "kittunderlay";
  bgpMED = -1;
  ipv6 = {
    #bgpImports = null;
    #bgpExportss = [ "2a12:dd47:9330::/44" ];

    #bgpExportss = null;
  };
  ipv4 = {
  };
}
