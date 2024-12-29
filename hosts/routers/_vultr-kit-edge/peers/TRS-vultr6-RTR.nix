{ ... }:
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
  localAS = 207175;
  peerAS = 64515;
  peerIP = "2001:19f0:ffff::1";
  multihop = 2;

  passwordRef = "vultr";

  ipv6 = {
    imports = null;
    exports = [
      "2a13:79c0:ff00::/40" # Prod /40

      # "2a12:dd47:9330::/44"
    ];
    #exports = null;
  };
}
