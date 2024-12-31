{ ... }:
{
  # type = "targetConfig";

  # bootdisk = "/dev/vda";
  # diskTemplate = "simple_singleFullRoot";

  # interface = "ens18";
  # mainSerial = 0;

  birdConfig = {
    #   # inherit transitInterface;
    extraForwardRules = ''
      iifname $wireguardIFACEs oifname "vlan36" ip6 daddr 2a13:79c0:ffff:feff:b00b:3615:1:0/112 counter accept
      oifname $wireguardIFACEs iifname "vlan36" ip6 saddr 2a13:79c0:ffff:feff:b00b:3615:1:0/112 counter accept
    '';

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
  };
}
