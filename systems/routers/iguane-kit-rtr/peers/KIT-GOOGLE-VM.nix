{kittenLib, ...}: let
  kittenASN = 4242421945;
in {
  peerAS = kittenASN;
#   peerIP = kittenLib.network.internal6.cafe.kittens.underlay "111";
  localAS = kittenASN;

  wireguard = {
    address = kittenLib.network.internal6.cafe.kittens.underlay "110";
    port = 51869;

    peerKey = "oQsOZ4fdPplLMrovlTPivyoaiiFrn40nPKxNzbPNy1U=";
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
