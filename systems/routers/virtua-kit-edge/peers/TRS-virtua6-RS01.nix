{...}: rec {
  #   enable = false;

  localAS = 213197;
  peerAS = 35661;
  peerIP = "2a0d:e680:0::b:1";
  multihop = 5;

  passwordRef = "virtua";

  ipv4.enable = false;
  ipv6 = {
    bgpImports = null;
    bgpExports = {
      ranges = ["2a12:5844:1310::/44"];
      prepend = 2;
      prependASN = localAS;
    };
    #exports = null;
  };
}
