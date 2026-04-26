args @ {
  pkgs,
  lib,
  ...
}: let
  kittenLib = {
    strings = import ./strings.nix args;
    network = import ./network args;
    peers = import ./peers.nix (args // {inherit kittenLib;});

    mkEnabledOption = desc:
      lib.mkEnableOption desc
      // {
        example = false;
        default = true;
      };

    withType = types: x: lib.toFunction types.${builtins.typeOf x} x;

    #attrsets = import ./attrsets.nix args;
    #options = import ./options.nix args;
  };
in
  kittenLib
