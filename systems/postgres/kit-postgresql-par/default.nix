# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  name,
  nodes,
  lib,
  pkgs,
  ...
}:
let
  diskoProfile = "simple";
  diskoConfig = {
    bootdisk = "/dev/vda";
  };
in
{
  imports = [
    # Include the results of the hardware scan.
    ../default.nix
    ./hardware-configuration.nix
    ./network-configuration.nix
  ];

  deployment = {
    # Disable SSH deployment. This node will be skipped in a
    # normal`colmena apply`.
    targetUser = "root";
    targetHost = "2a13:79c0:ffff:feff:b00b:3615:1:907"; # TODO: put HostName
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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

    # firewall = {
    #   enable = true;
    #   forward = {
    #     enable = true;
    #     # stateless = true;
    #     rules = ''
    #       iifname $wireguardIFACEs oifname "vlan36" ip6 daddr 2a13:79c0:ffff:feff:b00b:3615:1:0/112 counter accept
    #       oifname $wireguardIFACEs iifname "vlan36" ip6 saddr 2a13:79c0:ffff:feff:b00b:3615:1:0/112 counter accept
    #     '';
    #   };
    # };
  };
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  programs.mtr.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ ];
  networking.firewall.allowedUDPPorts = [ ];
  # Or disable the firewall altogether.
  networking.firewall.enable = lib.mkDefault true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  # system.stateVersion = "23.11"; # Did you read the comment?
}
