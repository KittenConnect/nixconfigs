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
    # ./firewall.nix # TODO: Remove
    ./postgres.nix
    ./packages.nix
  ];

  kittenModules = {
    loopback0 = {
      enable = lib.mkDefault true;
    };
  };

  # FireWall
  networking.firewall.allowedTCPPorts = [5432];
  networking.firewall.allowedUDPPorts = [5432];
}
