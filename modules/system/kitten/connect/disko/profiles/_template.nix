# Example to create a bios compatible gpt partition
args@{ lib, config, ... }:
let
  inherit (builtins) baseNameOf; # unsafeGetAttrPos;
  inherit (lib.strings) removeSuffix;
  # inherit (lib.attrsets) filterAttrs attrNames;

  fileName = baseNameOf (__curPos).file; # (__curPos) or (unsafeGetAttrPos "args" { inherit args; })
  profileName = lib.strings.removeSuffix ".nix" fileName;

  cfg = config.kittenModules.disko;
  profileConf = config.kittenModules.disko.${profileName};
in
{
  # Module Options
  # options.kittenModules.disko.${profileName} = {
  #   bootdisk = mkOption {
  #     type = types.str;
  #   };

  #   swapSize = mkOption {
  #     type = types.int;
  #     default = 0;
  #   };

  #   swapResume = mkEnableOption "Resume from swap" // {
  #     default = if swapSize > 0 then true else false;
  #   };
  # };

  # Implementation
  config = lib.mkIf (cfg.enable && cfg.profile == profileName) {
    # disko.memSize = 3072;

    disko.devices = {

    };
  };
}
