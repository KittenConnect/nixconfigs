let
  inherit ((import ../. {}).inputs) pkgs lib hive;

  isEligible = n: v: let
    config = v.config;
  in (v ? config && config ? nix && config.nix ? package);

  nodes = lib.filterAttrs isEligible hive.nodes;
  kernelPackages = lib.mapAttrs (n: v: v.config.boot.kernelPackages.kernel) nodes;
in
  kernelPackages // {_allPackages = pkgs.linkFarm "nix-tree-all-machines" kernelPackages;}
