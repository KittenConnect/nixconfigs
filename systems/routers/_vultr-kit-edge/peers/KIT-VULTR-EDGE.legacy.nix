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
  peerIP = "2a13:79c0:ffff:feff::113";
  localAS = kittenASN;

  wireguard = {
    # onIFACE = "test";
    address = "2a13:79c0:ffff:feff::112";
    port = 51802;
    endpoint = "[2a05:f480:1c00:5c0:5400:4ff:fe12:b47d]:51867";
    peerKey = "WYwm2mpTPQD5ZlKRI/l0GxJPUybN0cOyWxlTzNrZ7zY=";
  };
  template = "kittunderlay";
  bgpMED = 6666;
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
