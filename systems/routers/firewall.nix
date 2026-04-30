# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  lib,
  kittenLib,
  pkgs,
  targetConfig,
  birdConfig,
  ...
}: let
  IFACE =
    if targetConfig ? interface
    then targetConfig.interface
    else null;

  transitedNetworks =
    if (birdConfig ? transitNetworks && birdConfig.transitNetworks != null)
    then birdConfig.transitNetworks
    else [
      "2a12:5844:1310::/44" # Transits Customer ranges: 2a12:5844:131{0-f}::/48
      kittenLib.network.internal6.cafe.kittens.loopbacks.net
      kittenLib.network.internal6.cafe.kittens.underlay.routed.net
    ];

  transitIFACEs =
    [] ++ lib.optionals (birdConfig.transitInterfaces != []) birdConfig.transitInterfaces;
  # ++ lib.optional (birdConfig ? transitInterface) birdConfig.transitInterface;

  inherit
    (lib)
    mkAfter
    optional
    optionals
    optionalString
    concatStringsSep
    concatMapStringsSep
    attrNames
    filterAttrs
    ;
in {
  config = {
    kittenModules.firewall = {
      enable = true;
      forward = {
        enable = true;
        stateless = true;
        allowICMP = true;
        allowDnat = true;

        sets = {
          transitIFACEs = {
            setType = "ifname";
            elements = transitIFACEs;
          };
          transitNETs = {
            setType = "ipv6_addr";
            flags = ["interval"];
            elements = transitedNetworks;
          };
        };

        rules = ''
          ip6 saddr @transitNETs  iifname @kittenIFACEs  oifname @transitIFACEs  counter accept
          ip6 daddr @transitNETs  oifname @kittenIFACEs  iifname @transitIFACEs  counter accept
        '';
      };
    };

    networking.firewall.allowedTCPPorts = [22];
    networking.firewall.checkReversePath = false;
  };
}
