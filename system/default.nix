# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  sources,
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

  services.chrony = {
    enable = true;
  };

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
      channelUrlRev =
        s:
        lib.replaceStrings [ "/" ] [ "_" ] (
          lib.removePrefix "https://releases.nixos.org/" (lib.removeSuffix "/nixexprs.tar.xz" s)
        );

      sourceRevision =
        source:
        if source ? revision then
          "${source.version or source.branch}_${source.revision}"
        else
          (if source.type == "Channel" then channelUrlRev source.url else source.hash);

      getName = (p: if p ? name then "${p.name}" else "${p}");
      packages = builtins.map getName config.environment.systemPackages;
      sortedUnique = l: builtins.sort builtins.lessThan (lib.unique l);

      npinSources = builtins.sort builtins.lessThan (
        lib.mapAttrsToList (n: v: "npins-sources-${n}-${sourceRevision v}") sources
      );

      formatted = builtins.concatStringsSep "\n" ((sortedUnique npinSources) ++ [] ++ (sortedUnique packages));
    in
    formatted;
}
