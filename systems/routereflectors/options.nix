{ lib, pkgs, ... }:
let
  inherit (lib) mkOption genAttrs attrNames;
in
{
  options.hostprofile.rr = {
    #   iface = if targetConfig ? interface then targetConfig.interface else null;
    interface = mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "enp1s0";
      description = "device's principal interface (Management / UpLink)";
    };

    loopbacks =
      let
        protos = {
          ipv4 = {
            examples = [ "1.2.3.4/32" ];
            pretty = "IPv4";
          };

          ipv6 = {
            examples = [ "::2/128" ];
            pretty = "IPv6";
          };
        };
      in
      genAttrs (attrNames protos) (
        x:
        let
          proto = protos.${x};
        in
        lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = proto.examples;
          description = ''
            List of ${proto.pretty} loopbacks assigned.
          '';
        }
      );
  };
}
