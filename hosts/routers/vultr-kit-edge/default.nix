{ ... }:
let
  IFACE = "enp1s0";
in
{
  type = "targetConfig";

  bootdisk = "/dev/vda";
  diskTemplate = "simple_singleFullRoot";

  interface = IFACE;
  # mainSerial = 0;

  birdConfig = {
    transitInterface = IFACE;

    # router-id = ;

    # loopback4 = "";
    loopback6 = "2a13:79c0:ffff:fefe::b48d";

    static6 = [
      ''2001:19f0:ffff::1/128 via "fe80::fc00:4ff:fe82:5c6e%${IFACE}"'' # Vultr bgp neighbor

      "2a13:79c0:ffff:fefe::b00b/128 unreachable" # Special Anycast "loopback" for default gateways

      #"2a13:79c0:ffff::/48 unreachable" # Networking stuff
      #"2a13:79c0:ffff:fefe::/64 unreachable" # LoopBacks
      "2a13:79c0:ff00::/40 unreachable" # full range /40
    ];
  };
}
