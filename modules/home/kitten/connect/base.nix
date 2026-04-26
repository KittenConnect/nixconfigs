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
  inherit (kittenLib) mkEnabledOption;

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
