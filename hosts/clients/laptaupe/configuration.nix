# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  targetConfig,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # ../../../very/secret/path/s3nsible_config.nix
    ../../../_system/laptop.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  # # Not compatible for the moment
  # boot.initrd.luks.yubikeySupport = true;
  # boot.initrd.luks.fido2Support = true;

  # boot.initrd.systemd.enable = lib.mkForce false;
  # boot.plymouth.enable = lib.mkForce false;

  # better to enable it after first-install

  networking = {
    # networkmanager.enable = true;
    networkmanager =
      {
        enable = true;
      }
      // lib.mkIf (config.networking.networkmanager.enable) {
        extraConfig = lib.concatStringsSep "\n" [
          "[device]"
          "match-device=driver:iwlwifi"
          "wifi.scan-rand-mac-address=no"
        ];
      };
  };

  # Set your time zone.
  time.timeZone = "Europe/Paris";
  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = lib.mkForce "23.11"; # Did you read the comment?
}
