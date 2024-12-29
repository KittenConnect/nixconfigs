{ ... }:
let
  kittenASN = 4242421945;
in
{
  peerAS = kittenASN;
  peerIP = "2a13:79c0:ffff:feff::10f";
  localAS = kittenASN;

  wireguard = {
    address = "2a13:79c0:ffff:feff::10e";
    port = 51801;
    endpoint = "[2001:19f0:6801:365:5400:4ff:fe82:5c6e]:51801";
    peerKey = "H8z/i9mmbIukPwLJooVP/d+T4pi9IRFC/UYA7gcEzFM=";
  };

  template = "kittunderlay";
  bgpMED = 100;
  ipv6 = {
    #imports = null;
    bgpImports = "filter filter6_IN_BGP_%s";
    #exports = [ "2a12:dd47:9330::/44" ];

    #exports = null;
  };
  ipv4 = {
    bgpImports = "filter filter4_IN_BGP_%s";
    #exports = x: "filter6_IN_BGP_${toString x}";
  };
}
