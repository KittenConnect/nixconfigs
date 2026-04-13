{...}: {
  localAS = 213197;
  peerAS = 64515;
  peerIP = "2001:19f0:ffff::1";
  multihop = 2;

  passwordRef = "vultr";

  ipv6 = {
    bgpImports = null;
    bgpExports = [
      "2a12:5844:1310::/44" # Kitten Public IPv6
    ];
  };
}
