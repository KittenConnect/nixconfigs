{
  lib,
  kittenLib,
  ...
}: let
  kittenASN = 4242421945;
in {
  peerAS = 4242420263;
  peerIP = "fe80:1263::1:21";
  localAS = kittenASN;

  wireguard = {
    address = "fe80:1263::2:21";
    port = 42263;
    onIFACE = "vlan666";

    vrf = "DN42";

    endpoint = "fr-par1.flap42.eu:52033";
    peerKey = "/kwo9FiQRtgNyhMARTW9SvyvXIN7I7LfoICTytHjfA4=";
  };

  template = "dn42";
  # bgpMED = -1;
  ipv6 = {
    # bgpImports = { ranges = []; };
    bgpExports = { ranges = []; };
    #exports = [ "2a12:dd47:9330::/44" ];

    #exports = null;
  };
  ipv4 = {
    # bgpImports = { ranges = []; };
    bgpExports = null;
    #exports = x: "filter6_IN_BGP_${toString x}";
  };
}
