{ ... }:
let
  kittenASN = 4242421945;
in
{
  peerAS = kittenASN;
  peerIP = "2a13:79c0:ffff:feff::115";
  localAS = kittenASN;

  wireguard = {
    address = "2a13:79c0:ffff:feff::114";
    port = 51821;
    onIFACE = "ens18";

    # endpoint = "82.65.74.170:6969";
    peerKey = "tTY05MJgkKXf8pEZ4kC1TLWWTeIrh3KzyZdsmlUHTVM=";
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
