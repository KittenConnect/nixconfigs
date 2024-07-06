{ lib, config, pkgs, ... }:

let
  inherit (lib) mkOption stringLength types;

  cfg = config.kittenModules.loopback0;

  canonicalizeIPs = ips: lib.unique ips;

  hasIPv4 = (cfg.ipv4 != [ ]);
  isValidIPv4 = ip:
    let
      parts = lib.splitString "." ip;
      isByte = part: let n = builtins.parseInt part; in n >= 0 && n <= 255;
    in builtins.length parts == 4 && lib.all isByte parts;

  hasIPv6 = (cfg.ipv6 != [ ]);
  isValidIPv6 = ip:
    let
      parts = lib.splitString ":" ip;
      isHexPart = part:
        stringLength part <= 4
        && (part == "" || (builtins.match "[0-9a-fA-F]+" part != null));
    in builtins.length parts <= 8 && lib.all isHexPart parts && ip != "";

  validateIPv4s =
    ips:
    if lib.all isValidIPv4 ips then canonicalizeIPs ips else throw "Invalid IPv4 address in the list";

  validateIPv6s =
    ips:
    if lib.all isValidIPv6 ips then
      # builtins.trace
      # "IPs: ${builtins.toJSON ips} -> ${builtins.toJSON (canonicalizeIPs ips)}"
      (canonicalizeIPs ips)
    else
      throw "Invalid IPv6 address in the list";
in
{
  options.kittenModules.loopback0 = {
    enable = lib.mkEnableOption "loopback IP addresses module";
    hosts = lib.mkEnableOption "hosts entry for each loopback IP";

    ipv4 = mkOption {
      type = types.listOf types.str;
      description = "An array of IPv4 addresses.";
      default = [ ];
      example = [ "127.0.0.1" "192.168.0.1" ];
      apply = validateIPv4s;
    };

    ipv6 = mkOption {
      type = types.listOf types.str;
      description = "An array of IPv6 addresses.";
      default = [ ];
      example = [ "::1" "fe80::1" ];
      apply = validateIPv6s;
    };
  };

  config = lib.mkIf cfg.enable {
    # Add any additional configuration here.
    networking.extraHosts = lib.mkIf (cfg.hosts) (
      lib.concatMapStringsSep "\n" (ip: "${ip} ${config.networking.hostName}") (cfg.ipv4 ++ cfg.ipv6)
    );

    networking.interfaces.lo = lib.mkIf (hasIPv4 || hasIPv6) {
      ipv4.addresses = lib.mkIf (hasIPv4) (
        map (x: {
          address = "${toString x}";
          prefixLength = 32;
        }) cfg.ipv4
      );

      ipv6.addresses = lib.mkIf (hasIPv6) (
        map (x: {
          address = "${toString x}";
          prefixLength = 128;
        }) cfg.ipv6
      );
    };
  };
}
