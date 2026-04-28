{
  lib,
  kittenLib,
  ...
}: let
  kittenASN = 4242421945;
in {
  peerAS = kittenASN;
  # peerIP = kittenLib.network.internal6.cafe.kittens.underlay "114";
  localAS = kittenASN;

  wireguard = {
    address = kittenLib.network.internal6.cafe.kittens.underlay "3013";
    port = 51851;
    onIFACE = "vlan666";

    endpoint = "78.40.121.76:51851";
    peerKey = "gDriA5mhKKh44OHEIxmmevphoVRLK45TRJmFS1DV1i4=";
  };

  template = "kittunderlay";
  bgpMED = -1;
  ipv6 = {
    #imports = null;
    #exports = [ "2a12:dd47:9330::/44" ];

    #exports = null;
  };
  ipv4 = {
    #exports = x: "filter6_IN_BGP_${toString x}";
  };
}
