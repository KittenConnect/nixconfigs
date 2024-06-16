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
    #imports = null;
    imports = x: "filter filter6_IN_BGP_${toString x}";
    #exports = [ "2a12:dd47:9330::/44" ];

    #exports = null;
  };
  ipv4 = {
    imports = x: "filter filter4_IN_BGP_${toString x}";
    #exports = x: "filter6_IN_BGP_${toString x}";
  };
}
