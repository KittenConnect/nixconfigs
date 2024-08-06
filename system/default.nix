# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  ...
}:

{

  imports = [
    # ./nixConfig.nix
    # ./packages.nix # Install system-wide pkgs
    ./inputrc.nix # ReadLine config
    ./security.nix # PAM + SSH + Keys
    # ./firewall.nix

    # VPNs
    ./openvpn.nix
    ./wireguard.nix

    # Kernel / Bootloader
    # ./serial-com.nix
    # ./systemd-boot.nix
    # ./grub-boot.nix
  ];

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  boot.supportedFilesystems = [ "nfs" ];
  services.rpcbind.enable = true; # NFS - Client

  programs.zsh.enable = true; # Install System-Wide -> Config is done with home-manager

  environment.shells = with pkgs; [ zsh ];
  environment.pathsToLink = [ "/share/zsh" ]; # ZSH Completion

  # tmpFS on /tmp
  boot.tmp.useTmpfs = lib.mkDefault true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    # Additional packages
    # nix-inspect
  ];

  # Versions Dump
  environment.etc."current-system-packages".text =
    let
      getName = (p: if p ? name then "${p.name}" else "${p}");
      packages = builtins.map getName config.environment.systemPackages;
      sortedUnique = builtins.sort builtins.lessThan (lib.unique packages);
      formatted = builtins.concatStringsSep "\n" sortedUnique;
    in
    formatted;
}
