{ ... }:
let
  kittenASN = 4242421945;
in
{
  peerAS = kittenASN;
  peerIP = "2a13:79c0:ffff:feff::105";
  localAS = kittenASN;

  wireguard = {
    address = "2a13:79c0:ffff:feff::104";
    port = 51801;
    onIFACE = "ens18";
    # endpoint = "[2001:19f0:6801:365:5400:4ff:fe82:5c6e]:6969";
    endpoint = "140.82.55.252:6969";
    peerKey = "H8z/i9mmbIukPwLJooVP/d+T4pi9IRFC/UYA7gcEzFM=";
  };

  template = "kittunderlay";
  bgpMED = 100;
  ipv6 = {
    #bgpImports = null;
    bgpImports = "filter filter6_IN_BGP_%s";
    #bgpExportss = [ "2a12:dd47:9330::/44" ];

    #bgpExportss = null;
  };
  ipv4 = {
    bgpImports = "filter filter4_IN_BGP_%s";
    #bgpExportss = "filter6_IN_BGP_%s";
  };
}
