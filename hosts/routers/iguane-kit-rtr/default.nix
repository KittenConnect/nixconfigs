{ ... }:
{
  type = "targetConfig";

  bootdisk = "/dev/vda";
  diskTemplate = "simple_singleFullRoot";
  # profile = "routers";
  interface = "ens18";
  # mainSerial = 0;

  birdConfig = {
    # inherit transitInterface;

    # router-id = ;

    # loopback4 = "";
    loopback6 = "2a13:79c0:ffff:fefe::113:25";

    static6 = [
      "::/0 recursive 2a13:79c0:ffff:fefe::b00b"

      "2a13:79c0:ffff:fefe::113:91/128 via 2a13:79c0:ffff:feff:b00b:3965:113:92" # Announce RouteReflector LoopBack

      #"2a13:79c0:ffff::/48 unreachable" # Networking stuff
      #"2a13:79c0:ffff:fefe::/64 unreachable" # LoopBacks
      #"2a13:79c0:ff00::/40 unreachable" # full range /40
    ];

    # extra interfaces part of KittenNetwork (local-eth for ex)
    # allowedInterfaces = [];

    extraForwardRules = ''
      iifname $kittenIFACEs ip6 daddr 2a13:79c0:ffff:fefe::113:91 tcp dport { 179, 1790 } counter accept

      ip6 saddr 2a01:cb08:bbb:3700::/64 oifname ens19 counter accept

      iifname ens19 oifname $kittenIFACEs counter accept
      ct state vmap {
        established : accept,
        related : accept,
      # invalid : jump forward-allow,
      #   new : jump forward-allow,
      #   untracked : jump forward-allow,
      }

      # oifname $kittenIFACEs ip6 saddr 2a13:79c0:ffff:fefe::113:91 tcp sport { 179, 1790 } counter accept
    '';
  };
}
