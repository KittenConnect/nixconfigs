{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.hostprofile.rr;
in
{

  config = {

    # LoopBacks
    networking.interfaces.lo =
      let
        defPrefix = {
          ipv4 = 32;
          ipv6 = 128;
        };
        mkLoopBack = proto: loopback: {
          address = "${toString loopback}";
          prefixLength = defPrefix.${proto};
        };
      in
      {
        ipv4.addresses = lib.mkIf (cfg.loopbacks.ipv4 != [ ]) (map (mkLoopBack "ipv4") cfg.loopbacks.ipv4);
        ipv6.addresses = lib.mkIf (cfg.loopbacks.ipv6 != [ ]) (map (mkLoopBack "ipv6") cfg.loopbacks.ipv6);
      };
  };
}
