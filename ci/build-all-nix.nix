let
  sources = import ../npins;

  pkgs = import sources.nixpkgs { };
  inherit (pkgs) lib;

  hive = import ./hive.nix;
  isEligible =
    n: v:
    let
      config = v.config;
    in
    (
      v ? config
      && config ? nix
      && config.nix ? package
    );

  nodes = lib.filterAttrs isEligible hive.nodes;
  nixPackages = lib.mapAttrs (n: v: v.config.nix.package) nodes;
in
  nixPackages // { _allPackages = pkgs.linkFarm "nix-tree-all-machines" nixPackages;}