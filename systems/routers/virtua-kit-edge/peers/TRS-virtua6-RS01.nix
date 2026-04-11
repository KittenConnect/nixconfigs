{ ... }:
{
  localAS = 213197;
  peerAS = 35661;
  peerIP = "2a0d:e680:0::b:1";
  multihop = 5;

  passwordRef = "virtua";

  ipv6 = {
    bgpImports = null;
    bgpExports = [
      "2a12:5844:1310::/44" # AS 

      # "2a12:dd47:9330::/44"
    ];
    #exports = null;
  };
}
