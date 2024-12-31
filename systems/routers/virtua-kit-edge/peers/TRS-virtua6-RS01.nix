{ ... }:
{
  localAS = 207175;
  peerAS = 35661;
  peerIP = "2a0d:e680:0::b:1";
  multihop = 5;

  passwordRef = "virtua";

  ipv6 = {
    bgpImports = null;
    bgpExports = [
      "2a13:79c0:ff00::/40" # Prod /40

      # "2a12:dd47:9330::/44"
    ];
    #exports = null;
  };
}
