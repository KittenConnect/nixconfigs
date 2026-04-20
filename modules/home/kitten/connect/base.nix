args @ {
  lib,
  pkgs,
  sources,
  config,
  osConfig,
  options,
  ...
}: let
  nixOSutils = import "${pkgs.path}/nixos/lib/utils.nix" {inherit (args) lib config pkgs;};

  inherit (lib.options) mkEnableOption;
  inherit (nixOSutils) removePackagesByName;

  # Common packages to include everywhere
  defaultPackages = with pkgs; [
    fastfetch
    repgrep
    jq
    yq-go
    fzf
    mtr
    iperf3
    socat
    ipcalc
    q
    gnused
    gnutar
    gawk
    tree
    which
    file
    ethtool
    pciutils
    usbutils
    ncdu
    lsof

    vim # TODO: module w/ programs.<xx>
    tmux # TODO: module w/ programs.<xx>
  ];

  # Packages to include on machine with Display server
  XPackages = with pkgs; [
    cowsay
    mosh
  ];

  mkEnabledOption = desc:
    lib.mkEnableOption desc
    // {
      example = false;
      default = true;
    };

  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/x11/desktop-managers/pantheon.nix
  # notExcluded = pkg: (!(lib.elem pkg config.environment.pantheon.excludePackages));

  cfg = config.kittenHome.packages;
in {
  options.kittenHome.packages = {
    enable = mkEnabledOption "common kitten packages installation";

    defaultPackages = lib.options.mkOption {
      type = lib.types.listOf lib.types.package;
      default = defaultPackages ++ lib.optionals (osConfig.services.xserver.enable) XPackages;
      readOnly = true;
      description = "The list of default packages to install.";
    };

    excludedPackages = lib.options.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "The list of default packages to ignore.";
    };
  };

  config = lib.mkIf (cfg.enable) {
    # This module will be imported by all hosts
    home.packages = removePackagesByName (cfg.defaultPackages) cfg.excludedPackages;
  };
}
