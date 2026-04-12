{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.kittenModules.sysupgrade;
in
{
  options.kittenModules.sysupgrade = {
    enable = lib.mkEnableOption "Kitten System Upgrade package" // {
        default = true;
        example = false;
    };
  };

  config = {
    nixpkgs.overlays = [ (final: prev: { kitten-sysupgrade = pkgs.callPackage ./package.nix { }; }) ];

    environment.systemPackages = lib.mkIf (cfg.enable) (with pkgs; [ kitten-sysupgrade ]);
  };
}
