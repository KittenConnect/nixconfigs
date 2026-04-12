{lib, pkgs, config, ...}: let cfg = config.kittenModules.nixHome; in {
    imports = [
        ../../external/home-manager.nix
    ];

    options.kittenModules.nixHome = {
        enable = lib.mkEnableOption "use home-manager for root environment" // {
            default = true;
            example = false;
        };
    };

    config = lib.mkIf cfg.enable {
        users.users.root.shell = pkgs.zsh;
        programs.zsh.enable = true; # Install System-Wide -> Config is done with home-manager

        environment.shells = with pkgs; [ zsh ];
        environment.pathsToLink = [ "/share/zsh" ]; # ZSH Completions

        home-manager = {
            backupFileExtension = "hm_bkp";

            users.root = {pkgs, lib, osConfig, ...}: {
                home.stateVersion = lib.mkDefault osConfig.system.stateVersion;
                imports = [../../../home];
            };
        };
    };
}
