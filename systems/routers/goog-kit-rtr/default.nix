# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
args @ {
  config,
  lib,
  kittenLib,
  modulesPath,
  pkgs,
  ...
}: let
  diskoProfile = "simple";
  diskoConfig = {
    bootdisk = "/dev/vda";
  };

  peers = kittenLib.peers {
    host = ./peers;
    profile = ../.;

    blacklist = [];
    manual = {};
  };
in {
  imports = [
    ../profile.nix
    ./hardware-configuration.nix
    #     ./network-configuration.nix
    ../../google-cloud-profile.nix
    ../../../modules/system/kitten/connect/bird2/snippets/kittenCores.nix
  ];

  deployment = {
    # Disable SSH deployment. This node will be skipped in a
    # normal`colmena apply`.
    targetUser = builtins.getEnv "GCP_OSLOGIN_USER";
    targetHost = "goog-kit-rtr";
  };

  systemd.services."serial-getty@ttyS0".enable = lib.mkForce true;

  kittenModules = {
    disko = {
      enable = lib.mkForce false;
      profile = diskoProfile;

      ${diskoProfile} = diskoConfig;
    };

    bird = {
      enable = true;
      loopback6 = kittenLib.network.internal6.cafe.kittens.loopbacks.google;

      static6 = [
        "::/0 recursive ${kittenLib.network.internal6.cafe.kittens.loopbacks.internet}"
        "${kittenLib.network.internal6.cafe.kittens.loopbacks.ig1-kit-rr}/128 via ${kittenLib.network.internal6.cafe.kittens.underlay.routed.iguane}:91" # Announce RouteReflector LoopBack
      ];

      peers = peers.bird;
    };

    wireguard = {
      enable = true;
      # defaultIFACE = "eth0";
      peers = peers.wireguard;
    };

    firewall = {
      forward = {
        enable = true;
        keepInvalidState = true;
        rules = ''
          # iifname "''${kittenIFACE}" ip6 saddr 1010:cafe:ffff:feff:b00b:caca:b173:0/112 oifname $wireguardIFACEs counter accept
          iifname $wireguardIFACEs ip6 daddr ${kittenLib.network.internal6.cafe.kittens.loopbacks.ig1-kit-rr} tcp dport { 179, 1790 } counter accept
          iifname ens19 oifname $wireguardIFACEs counter accept
        '';
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
