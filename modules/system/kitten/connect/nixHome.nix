{lib,...}: {
    imports = [
        ../../external/home-manager.nix
    ];

    options.kittenModules.nixHome = {
        enable = lib.mkEnableOption "use home-manager for root environment";
    };

    config = {
        users.users.root.shell = pkgs.zsh;
        home-manager = {
            backupFileExtension = "hm_bkp";

            users.root = {pkgs, lib, osConfig, ...}: {
                home.stateVersion = lib.mkDefault osConfig.system.stateVersion;
                imports = [../../../home];
            };
        };
    };
}
