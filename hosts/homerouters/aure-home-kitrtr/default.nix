# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

args@{
  config,
  # targetConfig,
  lib,
  pkgs,
  ...
}:
let
  iface = "ens18";
  kittenIFACE = "ens19";
  diskoProfile = "simple";
  diskoConfig = {
    bootdisk = "/dev/vda";
  };

  peers = (import ./peers (args // { }));

  wgPeers = (
    lib.mapAttrs (n: v: v.wireguard) (lib.filterAttrs (n: v: v ? wireguard && v.wireguard != { }) peers)
  );

  birdPeers = (lib.mapAttrs (n: v: builtins.removeAttrs v [ "wireguard" ]) peers);
in
{
  #imports = [ ./wireguard.nix ];
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

  imports = [
    # Include the results of the hardware scan.
    ../default.nix
    ./hardware-configuration.nix
    ./network-configuration.nix
    # ./packages.nix

    ../../../modules/system/kitten/connect/bird2/snippets/kittendefaults.nix
  ];

  kittenModules = {
    disko = {
      enable = true;
      profile = diskoProfile;

      ${diskoProfile} = diskoConfig;
    };

    loopback0 = {
      enable = true;
      ipv6 = [ "2a13:79c0:ffff:fefe::22f0" ];
    };

    bird = {
      enable = true;
      loopback6 = "2a13:79c0:ffff:fefe::22f0";

      static6 = [
        "::/0 recursive 2a13:79c0:ffff:fefe::b00b"

        # "2a13:79c0:ffff:feff:b00b:caca:b173:0/112 unreachable" # Direct on ens19
        "2a13:79c0:fffe:100::/56 unreachable"

        #"2a13:79c0:ffff::/48 unreachable" # Networking stuff
        #"2a13:79c0:ffff:fefe::/64 unreachable" # LoopBacks
        #"2a13:79c0:ff00::/40 unreachable" # full range /40
      ];

      peers = birdPeers;
    };

    wireguard = {
      enable = true;

      peers = wgPeers;
    };

    firewall = {
      forward = {
        enable = true;
        rules = ''
          iifname "${kittenIFACE}" ip6 saddr 2a13:79c0:ffff:feff:b00b:caca:b173:0/112 oifname $wireguardIFACEs counter accept

          ct state vmap {
            established : accept,
            related : accept,
          # invalid : jump forward-allow,
          #   new : jump forward-allow,
          #   untracked : jump forward-allow,
          }
        '';
      };
    };
  };

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  nixpkgs.config.allowUnfree = true;
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
