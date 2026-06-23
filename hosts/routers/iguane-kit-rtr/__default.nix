{ ... }:
{
  ### type = "targetConfig";

  # mainSerial = 0;

  birdConfig = {
    # inherit transitInterface;

    # router-id = ;

    # loopback4 = "";
    # extra interfaces part of KittenNetwork (local-eth for ex)
    # allowedInterfaces = [ "bootstrap" ];

    extraForwardRules = ''

      iifname $kittenIFACEs ip6 daddr 2a13:79c0:ffff:fefe::113:91 tcp dport { 179, 1790 } counter accept
      oifname bootstrap ip6 daddr 2a13:79c0:ffff:feff:b00b:3965:222:0/112 counter accept

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
