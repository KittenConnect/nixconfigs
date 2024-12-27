args@{ lib, config, ... }:
let
  inherit (builtins) baseNameOf; # unsafeGetAttrPos;
  inherit (lib.strings) removeSuffix;
  # inherit (lib.attrsets) filterAttrs attrNames;

  fileName = baseNameOf (__curPos).file; # (__curPos) or (unsafeGetAttrPos "args" { inherit args; })
  profileName = lib.strings.removeSuffix ".nix" fileName;

  cfg = config.kittenModules.firewall;
in
{
  #   # Module Options
  #   options.kittenModules.firewall.${profileName} = {
  # 
  #   };

  # Implementation
  config = lib.mkIf (cfg.enable && cfg.profile == profileName) {

  };
}
