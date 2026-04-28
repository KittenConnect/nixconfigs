{ lib, ... }:
let
  kittenASN = 4242421945;
in
{
  peerAS = kittenASN;
  peerIP = "2a13:79c0:ffff:feff::114";
  localAS = kittenASN;

  wireguard = {
    address = "2a13:79c0:ffff:feff::115";
    # port = 51842;
    endpoint = "78.40.121.76:51821";
    peerKey = "gDriA5mhKKh44OHEIxmmevphoVRLK45TRJmFS1DV1i4=";
  };

  template = "kittunderlay";
  bgpMED = 100;
  ipv6 = {
    #imports = null;
    bgpImports = lib.mkForce "filter filter6_IN_BGP_%s";
    #exports = [ "2a12:dd47:9330::/44" ];

    #exports = null;
  };
  ipv4 = {
    bgpImports = lib.mkForce "filter filter4_IN_BGP_%s";
    #exports = x: "filter6_IN_BGP_${toString x}";
  };
}
