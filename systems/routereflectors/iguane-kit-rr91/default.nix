# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  kittenLib,
  pkgs,
  ...
}: let
  # cfg = config.hostprofile.rr;
  diskoProfile = "simple";
  diskoConfig = {
    bootdisk = "/dev/vda";
  };

  iface = "ens18";
  kittenIFACE = "ens19";
  lastByte = "92";
in
  #    config = {
  #      mainSerial = 0;
  #      hostprofile.rr = {
  #        interface = "ens18";
  #      };
  #    };
  {
    imports = [
      ../profile.nix
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./network-configuration.nix # TODO: implement
    ];
    # Bootloader.
    boot.loader.grub.efiSupport = false;
    boot.loader.grub.enable = true;

    deployment = {
      # Disable SSH deployment. This node will be skipped in a
      # normal`colmena apply`.
      targetHost = "kit-ig1-newrr";
    };

    # Kitten configuration
    kittenModules = {
      # network = {
      #   enable = true;
      #   interface = "ens18";
      #   address = "";
      # };

      disko = {
        enable = true;
        profile = diskoProfile;
        ${diskoProfile} = diskoConfig;
      };

      hyperglass.enable = true;

      loopback0 = {
        # Enabled by bird by default
        enable = true;
        ipv6 = [
          (kittenLib.network.internal6.cafe.kittens.loopbacks "113:91")
        ];
      };
    };

    systemd.network.enable = true;

    # Set your time zone.
    time.timeZone = "Europe/Paris";

    # This option defines the first version of NixOS you have installed on this particular machine,
    # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
    #
    # Most users should NEVER change this value after the initial install, for any reason,
    # even if you've upgraded your system to a new NixOS release.
    #
    # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
    # so changing it will NOT upgrade your system.
    #
    # This value being lower than the current NixOS release does NOT mean your system is
    # out of date, out of support, or vulnerable.
    #
    # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
    # and migrated your data accordingly.
    #
    # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
    system.stateVersion = "23.11"; # Did you read the comment?
  }
