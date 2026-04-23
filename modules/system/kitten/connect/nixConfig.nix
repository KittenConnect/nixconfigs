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

  mkEnabledOption = desc:
    lib.mkEnableOption desc
    // {
      example = false;
      default = true;
    };

  cfg = config.kittenModules.nixConfig;

  keepGenerations = default:
    if config.boot.loader.systemd-boot.enable
    then config.boot.loader.systemd-boot.configurationLimit
    else if config.boot ? lanzaboote && config.boot.lanzaboote.enable
    then config.boot.lanzaboote.configurationLimit
    else if config.boot.loader.grub.enable
    then config.boot.loader.grub.configurationLimit
    else if config.boot.loader.generic-extlinux-compatible.enable
    then config.boot.loader.generic-extlinux-compatible.configurationLimit
    else default;
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
