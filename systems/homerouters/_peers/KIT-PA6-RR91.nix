{ ... }:
let
    kittenASN = 1234567;
in
{
  peerAS = kittenASN;
  peerIP = ""; # TODO: set a dedicated IP
  localAS = kittenASN;

  multihop = 2; # TODO: once network established, find if required

  template = "rrserver";
  ipv6 = {
    #imports = null;
    #imports = x: "filter filter6_IN_BGP_${toString x}";
    #exports = [ "2a12:dd47:9330::/44" ];

    #exports = null;
  };
  ipv4 = {
    #imports = x: "filter filter4_IN_BGP_${toString x}";
    #exports = x: "filter6_IN_BGP_${toString x}";
  };
}
