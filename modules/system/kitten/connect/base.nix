args @ {
  lib,
  kittenLib,
  pkgs,
  sources,
  config,
  options,
  ...
}: let
  nixOSutils = import "${pkgs.path}/nixos/lib/utils.nix" {inherit (args) lib config pkgs;};

  inherit (lib.options) mkOption;
  inherit (lib) types;
  inherit (nixOSutils) removePackagesByName;

  defaultPackages = with pkgs; [
    vim
    wget
    curl
    fastfetch
    alejandra
  ];

  cfg = config.kittenModules.packages;
in {
  options.kittenModules.packages = {
    enable = mkOption {
      type = lib.types.bool;
      default = true;
      description = "common kitten packages installation";
    };

    defaultPackages = lib.options.mkOption {
      type = lib.types.listOf lib.types.package;
      default = defaultPackages;
      description = "The list of default packages to install.";
    };

    excludedPackages = lib.options.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "The list of default packages to ignore.";
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = removePackagesByName cfg.defaultPackages cfg.excludedPackages;
  };
}
