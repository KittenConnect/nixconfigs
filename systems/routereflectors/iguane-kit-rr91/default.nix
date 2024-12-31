# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  ...
}:
let
  # cfg = config.hostprofile.rr;

  diskoProfile = "simple";
  diskoConfig = {
    bootdisk = "/dev/vda";
  };

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
    # Include the results of the hardware scan.
    ../default.nix
    ./hardware-configuration.nix
    # ./network-configuration.nix # TODO: implement
  ];
  # Bootloader.
  boot.loader.grub.efiSupport = false;
  boot.loader.grub.enable = true;

  # Pick only one of the below networking options.
  networking = {
    #nameservers = [ "1.3.3.7" ];

    interfaces = lib.mkMerge [
      #      (lib.mkIf (cfg.interface != null) { "${cfg.interface}".useDHCP = true; })

      #      (lib.mkIf (kittenIFACE != null) {
      #        "${kittenIFACE}" = {
      #          # ipv4.addresses = [
      #          #   {
      #          #     address = "185.10.17.209";
      #          #     prefixLength = 24;
      #          #   }
      #          # ];
      #
      #          ipv6.addresses = [
      #            {
      #              # address = "2a13:79c0:ffff:feff:b00b:caca:b173:25";
      #              address = "2a13:79c0:ffff:feff:b00b:3965:113:${lastByte}";
      #              prefixLength = 112;
      #            }
      #          ];
      #        };
      #      })
    ];

    # defaultGateway = {
    #   address = "185.10.17.254";
    #   metric = 42;
    #   interface = iface;
    # };

    defaultGateway6 = {
      address = "2a13:79c0:ffff:feff:b00b:3965:113:25";
      metric = 42;
      interface = kittenIFACE;
    };

    useDHCP = false;
    #dhcpcd.enable = false;
  };

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

    loopback0 = { # Enabled by bird by default
      enable = true;
      ipv6 = ["2a13:79c0:ffff:fefe::113:91"];
    };
  };

  systemd.network.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  nixpkgs.config.allowUnfree = true;

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
