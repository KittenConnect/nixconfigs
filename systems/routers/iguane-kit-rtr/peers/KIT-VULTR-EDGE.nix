{kittenLib, ...}: let
  kittenASN = 4242421945;
in {
  peerAS = kittenASN;
  # peerIP = kittenLib.network.internal6.cafe.kittens.underlay "105";
  localAS = kittenASN;

  wireguard = {
    address = kittenLib.network.internal6.cafe.kittens.underlay "104";
    port = 51801;
    onIFACE = "ens18";
    # endpoint = "[2001:19f0:6801:365:5400:4ff:fe82:5c6e]:6969";
    endpoint = "140.82.55.252:6969";
    peerKey = "H8z/i9mmbIukPwLJooVP/d+T4pi9IRFC/UYA7gcEzFM=";
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
