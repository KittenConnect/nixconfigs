# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  ...
}:

{
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

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # FireWall
  networking.firewall.allowedTCPPorts = [ 5432 ];
  networking.firewall.allowedUDPPorts = [ 5432 ];

  # Net Basics
  networking.useNetworkd = true;
  systemd.network.enable = true;
  systemd.network.wait-online.enable = false;
}
