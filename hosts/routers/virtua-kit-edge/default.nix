{ ... }:
let
  IFACE = "ens18";
in
{
  type = "targetConfig";

  bootdisk = "/dev/sda";
  diskTemplate = "simple_singleFullRoot";
  swap = true;

  interface = IFACE;
  # mainSerial = 0;
  birdConfig = {
    transitInterface = IFACE;
    # router-id = ;

    # loopback4 = "";
    loopback6 = "2a13:79c0:ffff:fefe::12:10";

    static6 = [
      # ''2a0d:e680:0::b:1/128 via "enp1s0"'' # Vultr bgp neighbor
      "2a13:79c0:ffff:fefe::b00b/128 unreachable"
      #"2a13:79c0:ffff::/48 unreachable" # Networking stuff
      #"2a13:79c0:ffff:fefe::/64 unreachable" # LoopBacks
      "2a13:79c0:ff00::/40 unreachable" # full range /40
    ];
  };
}
