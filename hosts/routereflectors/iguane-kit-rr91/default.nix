{ ... }:
{
  type = "targetConfig";

  bootdisk = "/dev/vda";
  diskTemplate = "simple_singleFullRoot";

  # mainSerial = 0;

  config = {
    hostprofile.rr = {
      interface = "ens18";

      loopbacks = {
        ipv6 = [ "2a13:79c0:ffff:fefe::113:91" ];
      };
    };
  };

  # birdConfig = {
  #   # inherit transitInterface;

  #   # router-id = ;

  #   # loopback4 = "";
  #   loopback6 = "2a13:79c0:ffff:fefe::22f0";

  #   static6 = [
  #     "::/0 recursive 2a13:79c0:ffff:fefe::b00b"

  #     # "2a13:79c0:ffff:feff:b00b:caca:b173:0/112 unreachable" # Direct on ens19
  #     "2a13:79c0:fffe:100::/56 unreachable"

  #     #"2a13:79c0:ffff::/48 unreachable" # Networking stuff
  #     #"2a13:79c0:ffff:fefe::/64 unreachable" # LoopBacks
  #     #"2a13:79c0:ff00::/40 unreachable" # full range /40
  #   ];
  # };
}
