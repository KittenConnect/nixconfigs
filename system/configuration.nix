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

{

  imports = [
    ./pkgs.nix
    ./inputrc.nix # ReadLine config
    ./security.nix # PAM + SSH + Keys
    ./firewall.nix

    ./openvpn.nix
    ./wireguard.nix

    ./console.nix
    ./serial-com.nix
    ./systemd-boot.nix
    ./grub-boot.nix
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

  nix = {
    package = pkgs.nixFlakes;
    settings = {
      auto-optimise-store = true;
    };
    gc = {
      automatic = false; # TODO: Implement static N generations
      dates = "daily";
      options =
        let
          default = 10; # TODO: Find a better way to do it

          generations = builtins.toString (
            if config.boot.loader.systemd-boot.enable then
              config.boot.loader.systemd-boot.configurationLimit
            else if config.boot.loader.grub.enable then
              config.boot.loader.grub.configurationLimit
            else if config.boot.loader.generic-extlinux-compatible.enable then
              config.boot.loader.generic-extlinux-compatible.configurationLimit
            else
              default
          );
        in
        "--delete-older-than +${generations}"; # Not supported
    };
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
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
      getName = (p: if p ? name then "${p.name}" else "${p}");
      packages = builtins.map getName config.environment.systemPackages;
      sortedUnique = builtins.sort builtins.lessThan (lib.unique packages);
      formatted = builtins.concatStringsSep "\n" sortedUnique;
    in
    formatted;
}
