{ ... }:
{
  localAS = 123456;
  peerAS = 215359;
  peerIP = "";
  multihop = 5;

  passwordRef = "romain";

  ipv6 = {
    bgpImport = null;
    bgpExports = [
        "2a13:79c0:ff00::/40" # Prod /40 TODO: correct this once final allocation is done
    ];
    #exports = null;
  };

}
