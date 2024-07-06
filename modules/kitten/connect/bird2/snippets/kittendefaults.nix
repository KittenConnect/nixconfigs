{ lib, config, target, targetConfig, birdFuncs, ... }:
let
  inherit (lib)
    optional optionals optionalString mkOrder attrNames filterAttrs
    concatStringsSep concatMapStringsSep;
  in {}