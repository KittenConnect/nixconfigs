{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kittenModules.sysupgrade;
in {
  options.kittenModules.sysupgrade = {
    enable =
      lib.mkEnableOption "Kitten System Upgrade package"
      // {
        default = true;
        example = false;
      };
  };

  config = {
    nixpkgs.overlays = [
      (final: prev: {
        kitten-sysupgrade = pkgs.writeShellApplication {
          name = "kitten-sysupgrade";

          runtimeInputs = with pkgs; [
            nix
            curl
            jq
          ];

          text = builtins.readFile ./script.sh;
        };
      })
    ];

    environment.systemPackages = lib.mkIf (cfg.enable) (with pkgs; [kitten-sysupgrade]);
  };
}
