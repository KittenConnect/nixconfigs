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
  peerIP = "2a13:79c0:ffff:fefe::113:91";
  localAS = kittenASN;

  multihop = 5;

  # wireguard = {
  #   address = "2a13:79c0:ffff:feff::10c";
  #   port = 51800;
  #   peerKey = "rMTaMWJYlgTKJoE0PnVOo9SKHTppEfYK5KtWjBI9mC8=";
  # };
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
