{ ... }:
{
  type = "targetConfig";

  bootdisk = "/dev/vda";
  diskTemplate = "simple_singleFullRoot";

  interface = "ens18";
  # mainSerial = 0;

  birdConfig = {
    # inherit transitInterface;

    # router-id = ;

    # loopback4 = "";
    loopback6 = "2a13:79c0:ffff:fefe::69:25";

    static6 = [
      "::/0 recursive 2a13:79c0:ffff:fefe::b00b"

      #"2a13:79c0:ffff::/48 unreachable" # Networking stuff
      #"2a13:79c0:ffff:fefe::/64 unreachable" # LoopBacks
      #"2a13:79c0:ff00::/40 unreachable" # full range /40
    ];
  };
}
