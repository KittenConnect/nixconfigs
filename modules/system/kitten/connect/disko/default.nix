args @ {
  lib,
  kittenLib,
  pkgs,
  config,
  profile,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.strings) optionalString concatStringsSep;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (kittenLib) mkEnabledOption;
  inherit (lib) types mkAfter;

  quoteString = x: ''"${x}"'';

  cfg = config.kittenModules.disko;
in {
  options.kittenModules.disko = {
    enable = mkEnableOption "KittenConnect common disko module";

    profile = mkOption {
      type = types.nullOr types.str;
      default = "simple";
    };
  };

  imports = [
    ./profiles
  ];

  config = lib.mkIf (cfg.enable) {
    system.build = {
      diskoImagesCompressed =
        pkgs.runCommand "compressed-${config.system.build.diskoImages.name}" {
          # TODO: see if need prefer local + structuredAttrs + unsafe discard
        } ''
          pwd

          xz="${pkgs.xz}/bin/xz"

          mkdir -pv $out
          cd ${config.system.build.diskoImages}

          echo Compressing disk images with xz
          echo CAUTION: May take some times

          find . -name '*.raw' -print -exec bash -c "$xz -T0 --stdout '{}' > '$out/{}.xz'" \;
        '';
    };
  };
}
