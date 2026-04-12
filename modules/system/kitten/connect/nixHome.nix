{lib,...}: {
    imports = [
        ../../external/home-manager.nix
    ];

    options.kittenModules.nixHome = {
        enable = lib.mkEnableOption "use home-manager for root environment";
    };

    config = {
#         users.users.root.shell = pkgs.zsh;
        home-manager.users.root = {pkgs, lib, osConfig, ...}: {
            home = { inherit (osConfig.system) stateVersion; };
        };
#         home-config.lib.mkHomeConfiguration "root" "/root" [
#             ./_home/configuration.nix
#         ];
    };
}
