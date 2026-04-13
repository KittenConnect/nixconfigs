{
  lib,
  config,
  target,
  targetConfig,
  birdFuncs,
  ...
}: let
  inherit (lib) mkMerge mkOrder;
in {
  imports = [
    ./functions.nix
    ./templates.nix
  ];
}
