args@{
  lib,
  pkgs,
  sources,
  config,
  options,
  ...
}:
let
  nixOSutils = import "${sources.nixpkgs}/nixos/lib/utils.nix" { inherit (args) lib config pkgs; };

  inherit (lib.options) mkEnableOption;
  inherit (nixOSutils) removePackagesByName;

  defaultPackages = with pkgs; [
    vim
    wget
    curl
    fastfetch
    nixfmt
  ];

  mkEnabledOption =
    desc:
    lib.mkEnableOption desc
    // {
      example = false;
      default = true;
    };

  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/x11/desktop-managers/pantheon.nix
  # notExcluded = pkg: (!(lib.elem pkg config.environment.pantheon.excludePackages));

  cfg = config.kittenModules.packages;
in
{
  options.kittenModules.packages = {
    enable = mkEnabledOption "common kitten packages installation";

    defaultPackages = lib.options.mkOption {
      type = lib.types.listOf lib.types.package;
      default = defaultPackages;
      description = "The list of default packages to install.";
    };

    excludedPackages = lib.options.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "The list of default packages to ignore.";
    };
  };

  config = lib.mkIf (cfg.enable) {
    # This module will be imported by all hosts
    environment.systemPackages = removePackagesByName cfg.defaultPackages cfg.excludedPackages;
  };
}
