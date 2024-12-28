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
