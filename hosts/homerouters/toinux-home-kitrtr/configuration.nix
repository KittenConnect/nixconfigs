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
let
  iface = if targetConfig ? interface then targetConfig.interface else null;
in
# kittenIFACE = "ens19";
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

  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  networking = {
    #nameservers = [ "1.3.3.7" ];
    interfaces = {
      "${iface}".useDHCP = true;

      # "${kittenIFACE}" = {

      #   # ipv4.addresses = [
      #   #   {
      #   #     address = "185.10.17.209";
      #   #     prefixLength = 24;
      #   #   }
      #   # ];

      #   ipv6.addresses = [
      #     {
      #       address = "2a13:79c0:ffff:feff:b00b:3965:113:25";
      #       prefixLength = 112;
      #     }
      #   ];
      # };
    };

    # defaultGateway = {
    #   address = "185.10.17.254";
    #   metric = 42;
    #   interface = iface;
    # };

    # defaultGateway6 = {
    #   address = "fe80::1";
    #   metric = 42;
    #   interface = iface;
    # };

    useDHCP = false;
    #dhcpcd.enable = false;
  };

  systemd.network.enable = true;

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
