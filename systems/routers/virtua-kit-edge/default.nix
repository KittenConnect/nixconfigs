# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
args @ {
  config,
  kittenLib,
  lib,
  pkgs,
  ...
}: let
  diskoProfile = "simple";
  diskoConfig = {
    bootdisk = "/dev/sda";
    swapSize = 1024;
  };

  peers = kittenLib.peers {
    host = ./peers;
    profile = ../.;

    blacklist = ["KIT-VIRTUA-EDGE.legacy"];
    manual = {
      # Transit
      TRS_virtua6_RS01 = "TRS-virtua6-RS01.nix";
      TRS_virtua6_RS02 = "TRS-virtua6-RS02.nix";

      # Internal Tunnels
      vultrNix_PAR = "KIT-vultr-edge.nix";
      # LGC_virtua_PAR = ./KIT-VIRTUA-EDGE.legacy.nix;
    };
  };
in {
  imports = [
    ../profile.nix
    ./hardware-configuration.nix
    ./network-configuration.nix

    ../../../modules/system/kitten/connect/bird2/snippets/kittenCores.nix
  ];

  deployment = {
    # Disable SSH deployment. This node will be skipped in a
    # normal`colmena apply`.
    targetUser = "root";
    targetHost = "kit-virtua-edge"; # TODO: implement
  };

  # Bootloader.
  boot.loader.grub.efiSupport = false;
  boot.loader.grub.enable = true;

  kittenModules = {
    disko = {
      enable = true;
      profile = diskoProfile;

      ${diskoProfile} = diskoConfig;
    };

    gitnamed = {
      enable = true;
      masterURL = lib.mkForce null;
    };

    bird = {
      enable = true;

      loopback6 = kittenLib.network.internal6.cafe.kittens.loopbacks.virtua;

      static6 = [
        "${kittenLib.network.internal6.cafe.kittens.loopbacks.internet}/128 unreachable"
        #"2a13:79c0:ffff::/48 unreachable" # Networking stuff
        "2a12:5844:1310::/44 unreachable" # full range /40
      ];

      peers = peers.bird;
    };

    wireguard = {
      enable = true;
      # defaultIFACE = "ens18";
      peers = peers.wireguard;
    };

    firewall = {
      forward = {
        enable = true;
        keepInvalidState = true;
        # rules = '' ... '';
      };
    };
  };

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

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
