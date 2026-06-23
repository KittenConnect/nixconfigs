let
  sources = import ./npins;

  pkgs = import sources.nixpkgs { };
  lib = pkgs.lib;

  host = lib.removeSuffix "\n" (builtins.readFile /etc/hostname);
  node = (import ./ci/_makeHive.nix (import ./hive.nix)).nodes.${host};
in
node
