{kittenLib, ...}: let
  kittenASN = 4242421945;
in {
  peerAS = kittenASN;
  peerIP = kittenLib.network.internal6.cafe.kittens.underlay "102";
  localAS = kittenASN;

  wireguard = {
    address = kittenLib.network.internal6.cafe.kittens.underlay "103";
    port = 51800;
    onIFACE = "ens18";
    # endpoint = "[2a07:8dc0:19:1cf::1]:6969";
    endpoint = "185.10.17.209:6969";

    peerKey = "p200ujtoVhMNnbrdljxoHqAF7cbfRDRFTA+6ibGvIEg=";
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
