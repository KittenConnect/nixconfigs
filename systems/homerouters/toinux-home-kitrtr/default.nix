# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
args @ {
  config,
  lib,
  kittenLib,
  pkgs,
  ...
}: let
  peers = kittenLib.peers {
    host = ./peers;
    profile = ../.;

    blacklist = [];
    manual = {};
  };
in {
  imports = [
    ../profile.nix
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./network-configuration.nix
    ../../proxmox-image-profile.nix

    ../../../modules/system/kitten/connect/bird2/snippets/kittendefaults.nix
  ];

  deployment = {
    targetHost = "kit-toinux-rtr";
    # targetImage = "proxmox";
  };

  proxmox = {
    # cloudInit.enable = false; # me no need
    filenameSuffix = "21036_${config.deployment.targetHost}";

    qemuConf = {
      bios = "ovmf";
      net0 = "virtio=00:00:00:00:00:00,bridge=vmbr0,firewall=0";
    };
  };


  kittenModules = {
    disko.enable = lib.mkForce false;

    firewall = {
      enable = true;
      forward = {
        enable = true;
        # stateless = true;
        # rules = '' ... '';
      };
    };

    bird = {
      enable = true;
      loopback6 = kittenLib.network.internal6.cafe.kittens.loopbacks "69:25";

      static6 = [
        "::/0 recursive ${kittenLib.network.internal6.cafe.kittens.loopbacks.internet}"
      ];

      peers = peers.bird;
    };

    wireguard = {
      enable = true;

      peers = peers.wireguard;
    };

    # loopback0 = { # Enabled by bird by default
    #   enable = true;
    # };
  };

  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
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
  system.stateVersion = "25.11"; # Did you read the comment?
}
