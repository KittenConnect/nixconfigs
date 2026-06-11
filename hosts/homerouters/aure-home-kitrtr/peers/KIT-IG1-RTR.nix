{ ... }:
let
  kittenASN = 4242421945;
in
{
  peerAS = kittenASN;
  peerIP = "2a13:79c0:ffff:feff::53";
  localAS = kittenASN;

  wireguard = {
    address = "2a13:79c0:ffff:feff::52";
    # port = 51842;
    endpoint = "78.40.121.76:51842";
    peerKey = "gDriA5mhKKh44OHEIxmmevphoVRLK45TRJmFS1DV1i4=";
  };

  template = "kittunderlay";
  bgpMED = 100;
  ipv6 = {
    #bgpImports = null;
    bgpImports = "filter filter6_IN_BGP_%s";
    #bgpExports = [ "2a12:dd47:9330::/44" ];

    #bgpExports = null;
  };
  ipv4 = {
    bgpImports = "filter filter4_IN_BGP_%s";
    #bgpExports = "filter6_IN_BGP_${toString x}";
  };
}
