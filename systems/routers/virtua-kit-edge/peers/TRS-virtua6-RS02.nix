{ ... }:
rec {
#   enable = false;

  localAS = 213197;
  peerAS = 35661;
  peerIP = "2a0d:e680:0::b:2";
  multihop = 5;

  passwordRef = "virtua";

  ipv6 = {
    bgpImports = null;
    bgpExports = ''
      filter {
        # Kitten Public IPv6
        if ( net ~ [ "2a12:5844:1310::/44" ] ) then {
          if bgp_path ~ [= ${builtins.toString localAS} =] then {
            bgp_path.prepend(${builtins.toString localAS}); # Reduce priority artificially by prepending
          }
          accept;
        }
        reject;
      };
    '';
    #exports = null;
  };
}
