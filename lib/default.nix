args @ {
  pkgs,
  lib,
  ...
}: let
  kittenLib = {
    strings = import ./strings.nix args;
    network = import ./network args;
    peers = import ./peers.nix (args // {inherit kittenLib;});

    types = {
      inherit (import ./file-type.nix args) fileType;
    };
    #attrsets = import ./attrsets.nix args;
    #options = import ./options.nix args;
  };
in
  kittenLib
