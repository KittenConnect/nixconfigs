{ ... }:
let
  kittenASN = 4242421945;
in
{
  # vultr6
  # AS64515
  # Peer-IP : 2001:19f0:ffff::1

  # protocol bgp TRANSIT_VULTR6 {
  # 
  #     multihop 2;
  # 

  #     ipv6 {
  #             export filter {
  #             if ( net ~ [ 2a13:79c0:ff00::/40, 2a12:dd47:9330::/44 ] ) then {
  #                     accept;
  #             }
  #             reject;
  #         };
  #         import none;
  #     };
  # 
  # }
  peerAS = kittenASN;
  peerIP = "2a13:79c0:ffff:feff::110";
  localAS = kittenASN;

  wireguard = {
    address = "2a13:79c0:ffff:feff::111";
    port = 6978;
    # endpoint = "[2a07:8dc0:19:1cf::1]:51800";
    # peerKey = "p200ujtoVhMNnbrdljxoHqAF7cbfRDRFTA+6ibGvIEg=";
    peerKey = "rMTaMWJYlgTKJoE0PnVOo9SKHTppEfYK5KtWjBI9mC8=";
  };
  template = "kittunderlay";
  bgpMED = 6666;
  ipv6 = {
    #imports = null;
    bgpImports = "filter filter6_IN_BGP_%s";
    #exports = [ "2a12:dd47:9330::/44" ];

    #exports = null;
  };
  ipv4 = {
    bgpImports = "filter filter4_IN_BGP_%s";
    #exports = x: "filter6_IN_BGP_${toString x}";
  };
}
