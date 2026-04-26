{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kittenModules.rhabbit-consumer;
in {
  options.kittenModules.rhabbit-consumer = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Kitten RhabbitMQ messages consumer";
    };
  };

  config = {
    nixpkgs.overlays = [(final: prev: {rhabbitmq-consumer = pkgs.callPackage ./package.nix {};})];

    environment.systemPackages = lib.mkIf (cfg.enable) (with pkgs; [rhabbitmq-consumer]);
  };
}
