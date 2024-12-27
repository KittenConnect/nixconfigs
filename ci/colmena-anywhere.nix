let
  sources = import ../npins;
  pkgs = import sources.nixpkgs { };
  lib = pkgs.lib;

  getNodes = (import ./_makeHive.nix (import ../hive.nix)).nodes;

  isEligible =
    n: v:
    let
      config = v.config;
    in
    (
      v ? config
      && config ? system
      && config.system ? build
      && config.system.build ? toplevel
      && config.system.build ? diskoScriptNoDeps
    );

  nodes = lib.filterAttrs isEligible getNodes;

  mkOutput =
    v:
    let
      config = v.config;
    in
    {
      nixos-system = config.system.build.toplevel;
      disko-script = config.system.build.diskoScriptNoDeps;
    };
in
# mkOutput = (name: value: mkValue value.config);
lib.mapAttrs (_: mkOutput) nodes
