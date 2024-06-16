{ ... }:
let
  kittenASN = 4242421945;
  toinuxASN = 4242423692;
in
{
  peerAS = toinuxASN;
  peerIP = "2a13:79c0:ffff:feff::3013";
  localAS = toinuxASN;

  wireguard = {
    address = "2a13:79c0:ffff:feff::3012";
    port = 51851;
    onIFACE = "ens18";

    peerKey = "xFNmHprArmxWD0W0YhD8nQZR1EbpXNWU8Rr5puSrDyw=";
  };

  template = "kittunderlay";
  bgpMED = 100;
  ipv6 = {
    #imports = null;
    imports = x: "filter filter6_IN_BGP_${toString x}";
    #exports = [ "2a12:dd47:9330::/44" ];

    #exports = null;
  };
  ipv4 = {
    imports = x: "filter filter4_IN_BGP_${toString x}";
    #exports = x: "filter6_IN_BGP_${toString x}";
  };
}
