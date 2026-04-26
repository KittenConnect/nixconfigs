{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kittenModules.hyperglass;
  hyperglass = pkgs.callPackage ./package.nix {
    pythonPackages = pkgs.python312Packages;
    inherit pkgs;
  };
in {
  options.kittenModules.hyperglass = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Kitten Looking Glasse service";
    };
  };

  config = lib.mkMerge [
    {
      nixpkgs.overlays = [(final: prev: {inherit hyperglass;})];
    }

    (lib.mkIf (cfg.enable) {
      environment.systemPackages = with pkgs; [hyperglass];
      # systemd.services.hyperglass = {
      # TODO: implement something
      # };
    })
  ];
}
