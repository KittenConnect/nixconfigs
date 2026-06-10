# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  kittenLib,
  pkgs,
  ...
}: {
  kittenModules.firewall = {
    enable = true;
    forward = {

      nat = {
        netmaps = {
          "2a12:5844:1311:feff::/64" = kittenLib.network.internal6.cafe.kittens.underlay.net;
          "2a12:5844:1311:fefe::/64" = kittenLib.network.internal6.cafe.kittens.loopbacks.net;
        };
      };
    };
  };

  kittenModules.vrfs.enable = true;
}
