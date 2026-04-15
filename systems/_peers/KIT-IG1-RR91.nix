{kittenLib, ...}: let
  inherit (kittenLib.params.internal6) asn;
in {
  peerAS = asn;
  peerIP = kittenLib.params.internal6.cafe.kittens.loopbacks.ig1-kit-rr;
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
