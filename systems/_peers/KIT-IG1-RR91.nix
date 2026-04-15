{kittenLib, ...}: let
  inherit (kittenLib.network.internal6) asn;
in {
  peerAS = asn;
  peerIP = kittenLib.network.internal6.cafe.kittens.loopbacks.ig1-kit-rr;
  localAS = asn;

  multihop = 5;

  template = "rrserver";

  # ipv6 = {
  #
  # };

  # ipv4 = {
  #
  # };
}
