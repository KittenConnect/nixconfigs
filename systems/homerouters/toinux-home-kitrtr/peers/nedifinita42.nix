{
  lib,
  kittenLib,
  ...
}: let
  kittenASN = 4242421945;
in {
  peerAS = 4242420454;
  peerIP = "fe80::454:102";
  localAS = kittenASN;

  wireguard = {
    address = "fe80::4242:1945:0:3";
    port = 51842;
    onIFACE = "vlan666";

    endpoint = "[2001:bc8:711:26fc:dc00:ff:feed:4ab]:43571";
    peerKey = "pCTgngczpFgIDbZzfxtz6tiaiFo59b2GbeJEEc21mA0=";
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
