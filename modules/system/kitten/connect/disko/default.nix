args@{
  lib,
  pkgs,
  config,
  profile,
  ...
}:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.strings) optionalString concatStringsSep;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib) types mkAfter;

  quoteString = x: ''"${x}"'';

  mkEnabledOption =
    desc:
    lib.mkEnableOption desc
    // {
      example = false;
      default = true;
    };

  cfg = config.kittenModules.disko;
in
{
  options.kittenModules.disko = {
    enable = mkEnableOption "KittenConnect common disko module";

    profile = mkOption {
      type = types.str;
      default = "simple";
    };
  };

  imports = [
    ./profiles
  ];

  config = lib.mkIf (cfg.enable) {  };
}
