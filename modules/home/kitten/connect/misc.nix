{
  pkgs,
  lib,
  config,
  options,
  osConfig,
  ...
}: let
  cfg = config.kittenHome;
in {
  config = lib.mkIf (cfg.common) {
    # Basic env variables
    home.sessionVariables = {
      EDITOR = "vim";
    };

    # xProfile fix maybe usefull
    # home.file.".xprofile".text = ''
    #   if [ -e $HOME/.profile ]
    #   then
    #       . $HOME/.profile
    #   fi
    # '';


    # Versions Dump
    home.file."current-home-packages".text =
      let
        getName = (p: if p ? name then "${p.name}" else "${p}");
        packages = builtins.map getName config.home.packages;
        sortedUnique = builtins.sort builtins.lessThan (lib.unique packages);
        formatted = builtins.concatStringsSep "\n" sortedUnique;
      in
      formatted;
  };
}
