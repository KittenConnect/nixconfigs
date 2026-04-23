# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  sources,
  ...
}: {
  imports = [
    # ./nixConfig.nix
    # ./packages.nix # Install system-wide pkgs
    ./inputrc.nix # ReadLine config
    # ./firewall.nix

    # Kernel / Bootloader
    # ./serial-com.nix
    # ./systemd-boot.nix
    # ./grub-boot.nix
  ];

  boot.supportedFilesystems = ["nfs"];
  services.rpcbind.enable = true; # NFS - Client

  services.chrony = {
    enable = true;
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
}
