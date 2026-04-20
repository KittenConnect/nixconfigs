{kittenLib, ...}: let
  kittenASN = 4242421945;
in {
  peerAS = kittenASN;
  peerIP = kittenLib.network.internal6.cafe.kittens.underlay "53";
  localAS = kittenASN;

  wireguard = {
    address = kittenLib.network.internal6.cafe.kittens.underlay "52";
    # port = 51842;
    endpoint = "78.40.121.76:51842";
    peerKey = "gDriA5mhKKh44OHEIxmmevphoVRLK45TRJmFS1DV1i4=";
  };

  template = "kittunderlay";
  bgpMED = 100;
  ipv6 = {
    #bgpImports = null;
    #bgpExports = [ "2a12:dd47:9330::/44" ];

    #bgpExports = null;
  };
  ipv4 = {
    #bgpExports = "filter6_IN_BGP_${toString x}";
  };
}
