args @ {
  pkgs,
  lib,
  ...
}: let
  kittenLib = {
    strings = import ./strings.nix args;
    network = import ./network args;
    peers = import ./peers.nix (args // {inherit kittenLib;});

    #attrsets = import ./attrsets.nix args;
    #options = import ./options.nix args;
  };
in
  kittenLib
