{ ... }:
let
  kittenASN = 4242421945;
in
{
  peerAS = kittenASN;
  peerIP = "2a13:79c0:ffff:feff::52";
  localAS = kittenASN;

  wireguard = {
    address = "2a13:79c0:ffff:feff::53";
    port = 51842;
    onIFACE = "ens18";

    peerKey = "M/aH47ot5gjYcF2D3gG2uM087pq/FrbmBzd2s/Q0Uno=";
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
