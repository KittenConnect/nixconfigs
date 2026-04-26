# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  ...
}: {

  imports = [
    # ./firewall.nix # TODO: cleanup + enable
  ];

  kittenModules.gitnamed = {
    enable = lib.mkDefault false;
    masterURL = "git@ns.kittenconnect.net:gitnamed";
  };
}
