{kittenLib, ...}: let
  kittenASN = 4242421945;
in {
  peerAS = kittenASN;
  peerIP = kittenLib.network.internal6.cafe.kittens.underlay "52";
  localAS = kittenASN;

  wireguard = {
    address = kittenLib.network.internal6.cafe.kittens.underlay "53";
    port = 51842;
    onIFACE = "ens18";

    peerKey = "M/aH47ot5gjYcF2D3gG2uM087pq/FrbmBzd2s/Q0Uno=";
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
