{
  lib,
  pkgs,
  config,
  options,
  modulesPath,
  sources,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.kitten) mkEnabledOption;

  cfg = config.kittenModules.nixConfig;

  keepGenerations = let 
    limitSources = [
      { cond = config.boot.loader.systemd-boot.enable; value = config.boot.loader.systemd-boot.configurationLimit; }
      { cond = config.boot ? lanzaboote && config.boot.lanzaboote.enable; value = config.boot.lanzaboote.configurationLimit; }
      { cond = config.boot.loader.grub.enable; value = config.boot.loader.grub.configurationLimit; }
      { cond = config.boot.loader.generic-extlinux-compatible.enable; value = config.boot.loader.generic-extlinux-compatible.configurationLimit; }
    ];
  in
    default: builtins.head ((lib.foldl (acc: x: acc ++ lib.optional x.cond x.value) [] limitSources) ++ [default]);
in {
  options.kittenModules.nixConfig = {
    enable = mkEnabledOption "kitten common nix-specific configuration";
    autoGc = mkEnabledOption "kitten automatic Nix Garbage-Collect all generations absent from BootLoader";

    keepNGenerations = mkOption {
      type = lib.types.int;
      default = let
        v = keepGenerations cfg.defaultKeepNGenerations;
      in
        if v != null
        then v
        else cfg.defaultKeepNGenerations;
    };

    nixosFolder = mkOption {
      type = with lib.types; nullOr types.path;
      default = if sources ? self then sources.self.outPath else null;
    };

    defaultKeepNGenerations = mkOption {
      type = lib.types.int;
      default = 10;
    };
  };

  # Implementation

  config = lib.mkIf (cfg.enable) {
    environment.etc.nixos = lib.mkIf (cfg.nixosFolder != null) { source = cfg.nixosFolder; };

    systemd.services.nix-gc = lib.mkIf (cfg.autoGc) (
      let
        nixProfile = "/nix/var/nix/profiles/system";
      in {
        preStart = "${config.nix.package}/bin/nix-env --delete-generations +${builtins.toString cfg.keepNGenerations} --profile ${nixProfile}";
        postStop = "${nixProfile}/bin/switch-to-configuration boot";
      }
    );

    systemd.timers.nix-gc.timerConfig = lib.mkIf (cfg.autoGc) {
      OnBootSec = "10m";
    };

    nix = {
      # package = pkgs.nixFlakes;
      settings = {
        auto-optimise-store = true;
      };

      package = pkgs.lix;

      gc = lib.mkIf (cfg.autoGc) {
        dates = "daily";
        automatic = lib.mkDefault true;
      };

      channel.enable = false;

      nixPath = [
        "nixpkgs=${pkgs.path}"
      ];

      extraOptions = ''
        experimental-features = nix-command flakes
      '';
    };
  };
}
