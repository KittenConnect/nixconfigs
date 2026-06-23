#TODO: tunnel between pa6 <-> ig1
{ ... }:
let
  kittenASN = 4242421945;
in
{
  peerAS = kittenASN;
  peerIP = "2001:67c:2564:800::103";
  localAS = kittenASN;
  wireguard = {
    address = "2001:67c:2564:800::102";
    port = 6969;

    peerKey = "gDriA5mh";
  };

  template = "kittunderlay";
  bgpMED = 100;
  ipv6 = {
      #imports = null;
      bgpImports = "filter filter6_IN_BGP_%s";
      #exports = [ "2a12:dd47:9330::/44" ];

      #exports = null;
  };
}
