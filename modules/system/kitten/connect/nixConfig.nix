{
  lib,
  pkgs,
  config,
  options,
  ...
}:
let
  inherit (lib.options) mkOption mkEnableOption;

  mkEnabledOption =
    desc:
    lib.mkEnableOption desc
    // {
      example = false;
      default = true;
    };

  cfg = config.kittenModules.nixConfig;
in
{
  options.kittenModules.nixConfig = {
    enable = mkEnabledOption "kitten common nix-specific configuration";

    keepNGenerations = mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
    };
  };

  config = lib.mkIf (cfg.enable) {

    nix = {
      #package = pkgs.nixFlakes;
      settings = {
        auto-optimise-store = true;
      };

      gc = lib.mkIf (config.nix.gc.automatic) {
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
  };
}
