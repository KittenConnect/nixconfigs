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
  # diskoProfile = "simple";
  # diskoConfig = {
  #   bootdisk = "/dev/vda";
  # };
  peers = kittenLib.peers {
    host = ./peers;
    profile = ../.;

    blacklist = [];
    manual = {};
  };
in {
  services.xserver.xkb = {
    layout = "fr";
    #variant = "";
  };

  imports = [
    ../profile.nix
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./network-configuration.nix
    # ./packages.nix

    ../../../modules/system/kitten/connect/bird2/snippets/kittendefaults.nix
  ];

  # Bootloader.
  #boot.loader.systemd-boot.enable = true;
  #boot.loader.systemd-boot.configurationLimit = 5;
  #boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.efiSupport = false;
  boot.loader.grub.enable = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  #boot.loader.grub.devices = [ "${targetConfig.bootdisk}" ]; # or "nodev" for efi only

  kittenModules = {
    disko = let
      profile = "simple";
    in {
      enable = true;
      inherit profile;

      ${profile} = {
        bootdisk = "/dev/vda";
      };
    };

    firewall = {
      enable = true;
      forward = {
        enable = true;
        # stateless = true;
        rules = ''
          iifname @kittenIFACEs oifname "vlan36" ip6 daddr 1010:cafe:ffff:feff:b00b:3615:1:0/112 counter accept
          oifname @kittenIFACEs iifname "vlan36" ip6 saddr 1010:cafe:ffff:feff:b00b:3615:1:0/112 counter accept
        '';
      };
    };

    bird = {
      enable = true;
      loopback6 = kittenLib.network.internal6.cafe.kittens.loopbacks "2:256";

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
  system.stateVersion = lib.mkForce "24.05"; # Did you read the comment?
}
