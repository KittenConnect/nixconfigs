{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.kittenModules.rhabbit-consumer;
in
{
  options.kittenModules.rhabbit-consumer = {
    enable = lib.mkEnableOption "Kitten RhabbitMQ messages consumer";
  };

  config = {
    nixpkgs.overlays = [ (final: prev: { rhabbitmq-consumer = pkgs.callPackage ./package.nix { }; }) ];

    environment.systemPackages = lib.mkIf (cfg.enable) (with pkgs; [ rhabbitmq-consumer ]);
  };
}
