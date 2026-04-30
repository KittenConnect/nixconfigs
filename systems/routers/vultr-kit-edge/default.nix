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
    bootdisk = "/dev/vda";
    # swapSize = 1024;
  };

  peers = kittenLib.peers {
    host = ./peers;
    profile = ../.;

    blacklist = [];
    manual = {
      TRS_VULTR4_PAR = {
        localAS = 213197;
        peerAS = 64515;
        peerIP = "169.254.169.254";
        multihop = 2;

        passwordRef = "vultr";

        ipv6.enable = false;
        ipv4 = {
          bgpImports = { ranges = ["0.0.0.0/0"];};
          bgpExports = {
            ranges = [
              "0.0.0.0/0{32,32}" # Kitten Reserved IPv4
            ];
          };
        };
      };
      TRS_VULTR6_PAR = {
        localAS = 213197;
        peerAS = 64515;
        peerIP = "2001:19f0:ffff::1";
        multihop = 2;

        passwordRef = "vultr";

        ipv4.enable = false;
        ipv6 = {
          bgpImports = null;
          bgpExports = {
            ranges = [
              "2a12:5844:1310::/44" # Kitten Public IPv6
            ];
          };
        };
      };
    };
  };
in {
  imports = [
    ../profile.nix
    ./hardware-configuration.nix
    ./network-configuration.nix # included here because of its simplicity
    # ./cloud-init.nix

    ../../../modules/system/kitten/connect/bird2/snippets/kittenCores.nix
  ];

  deployment = {
    # Disable SSH deployment. This node will be skipped in a
    # normal`colmena apply`.
    targetUser = "root";
    targetHost = "kit-vultr-edge"; # TODO: implement
  };

  # Bootloader.
  boot.loader.grub.efiSupport = false;
  boot.loader.grub.enable = true;

  virtualisation.vmVariant = {
    services.cloud-init.enable = lib.mkForce false;
  };

  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network.enable = true;

  kittenModules = {
    disko = {
      enable = true;
      profile = diskoProfile;

      ${diskoProfile} = diskoConfig;
    };

    gitnamed = {
      enable = true;
    };

    bird = {
      enable = true;

      loopback6 = kittenLib.network.internal6.cafe.kittens.loopbacks.vultr;

      static6 =
        [
          "${kittenLib.network.internal6.cafe.kittens.loopbacks.internet}/128 unreachable" # Special Anycast "loopback" for default gateways

          # "2a13:79c0:ffff::/48 unreachable" # Networking stuff
          # "2a12:5844:1310::/44 unreachable" # full range /40
          "2a12:5844:1310::/44 unreachable" # New range /44
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
