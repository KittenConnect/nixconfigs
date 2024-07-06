{
  lib,
  targetConfig,
  target,
  profile,
  ...
}:
let
  inherit (lib) mkOption types mkIf;
in
#   cfg = config.customModules.autodisko;
{
  #   options = {
  #     customModules.autodisko.diskTemplate = mkOption {
  #       type = types.nullOr types.str;
  #       default = null;
  #       description = ''
  #         Disk template for the target configuration.
  #       '';
  #     };

  #   };

  # Implementation
  imports = [
    (
      if (targetConfig.diskTemplate) then
        (../../../_diskos + "/${targetConfig.diskTemplate}.nix")
      else
        (
          let
            diskoCfg = (./hosts + "/${profile}/${target}/disk-config.nix");
          in
          (
            assert (builtins.pathExists diskoCfg)
              "${target}: diskTemplate undefined and ${diskoCfg} inexistant, dunno what to do";
            diskoCfg
          )
        )
    )
  ];
}
