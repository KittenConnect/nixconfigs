{lib, withCIDR, ...}: rec {
  dn42 = withCIDR {
    asn = 4242421945;
    net = "fd42:7331:1241::/48";

    fromInternal = internal6.cafe.kittens;
  };

  public = withCIDR {
    asn = 213197;
    net = "2a12:5844:1310::/44";

    kittens = withCIDR { 
      net = "2a12:5844:1311::/48";
      fromInternal = internal6.cafe.kittens; 
    };
    customers = withCIDR { 
      net = "2a12:5844:1312::/48";
      fromInternal =  internal6.cafe.customers; 
    };
  };

  internal6 = withCIDR {
    asn = 4242421945;
    net = "1010::/16";

    cafe = withCIDR {
      net = "${internal6}:cafe::/32";

      customers = withCIDR "${internal6.cafe}:fffe::/48";
      kittens = withCIDR {
        net = "${internal6.cafe}:ffff::/48";

        loopbacks = withCIDR {
          net = "${internal6.cafe.kittens}:fefe::/64";

          internet = "${internal6.cafe.kittens.loopbacks}::b00b";

          vultr = "${internal6.cafe.kittens.loopbacks}::b48d";
          virtua = "${internal6.cafe.kittens.loopbacks}::12:10";
          google = "${internal6.cafe.kittens.loopbacks}::4012:1";

          ig1-kit-rtr = "${internal6.cafe.kittens.loopbacks}::113:25";
          ig1-kit-rr = "${internal6.cafe.kittens.loopbacks}::113:91";
        };

        underlay = withCIDR {
          net = "${internal6.cafe.kittens}:feff::/64";

          routed = withCIDR {
            net = "${internal6.cafe.kittens.underlay}:b00b::/80";

            iguane = withCIDR "${internal6.cafe.kittens.underlay.routed}:3965:113:0/112";
            aure = withCIDR "${internal6.cafe.kittens.underlay.routed}:caca:b173:0/112";
          };
        };
      };
    };
  };
}
