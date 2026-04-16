{kittenLib, ...}: let
  kittenASN = 4242421945;
in {
  peerAS = kittenASN;
  peerIP = "1010:cafe:ffff:feff::10e";
  localAS = kittenASN;

  wireguard = {
    address = "1010:cafe:ffff:feff::10f";
    port = 51801;
    endpoint = "[2a07:8dc0:19:1cf::1]:51801";
    peerKey = "p200ujtoVhMNnbrdljxoHqAF7cbfRDRFTA+6ibGvIEg=";
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
