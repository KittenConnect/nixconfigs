{lib, ...}: let
  getPrefix = x:
    if builtins.isString x._prefix
    then x._prefix
    else x._prefix.prefix;

  stringable = args:
    {
      __toString = getPrefix;
    }
    // args;

  cidr = args:
    {
      __toString = self: "${self.prefix}::/${builtins.toString self.len}";
    }
    // args;

  withCIDR = let
    getCidr = self: let
      split = lib.splitString "/" self.net;
      len = builtins.length split;
    in
      lib.throwIf (len != 2) "cidr must be of form 0000:0000:0000::/xx" (builtins.elemAt split (len - 1));
  in
    args:
      if builtins.isAttrs args
      then
        {
          __toString = self: let
            split = lib.splitString "/" self.net;
            prefix = builtins.head split;

            cleanPrefix = let
              splitPrefix = lib.splitString ":" prefix;
              len = builtins.length splitPrefix;
              cleanSplit =
                if len >= 8
                then
                  lib.throwIf ((builtins.elemAt splitPrefix 7) != "0") "IPv6 prefixes must start at a 0 boundary" (
                    lib.sublist 0 (len - 1) splitPrefix
                  )
                else if
                  lib.sublist (len - 2) 2 splitPrefix
                  == [
                    ""
                    ""
                  ]
                then lib.sublist 0 (len - 2) splitPrefix
                else splitPrefix;
            in
              lib.concatStringsSep ":" cleanSplit;
          in "${cleanPrefix}";

          len = lib.toInt (getCidr args);
        }
        // args
      else withCIDR {net = args;};
in rec {
  internal6 = withCIDR {
    net = "1010::/16";

    cafe = withCIDR {
      net = "${internal6}:cafe::/32";

      customers = "${internal6.cafe}:fffe";
      kittens = withCIDR {
        net = "${internal6.cafe}:ffff::/48";

        loopbacks = withCIDR {
          net = "${internal6.cafe.kittens}:fefe::/64";

          internet = "${internal6.cafe.kittens.loopbacks}::b00b";

          vultr = "${internal6.cafe.kittens.loopbacks}::b48d";

          ig1-kit-rtr = "${internal6.cafe.kittens.loopbacks}::113:25";
          ig1-kit-rr = "${internal6.cafe.kittens.loopbacks}::113:91";
        };

        underlay = withCIDR {
          net = "${internal6.cafe.kittens}:feff::/64";

          homes = withCIDR {
            net = "${internal6.cafe.kittens.underlay}:b00b::/80";

            iguane = withCIDR "1010:cafe:ffff:feff:b00b:3965:113::/112";
          };
        };
      };
    };
  };
}
