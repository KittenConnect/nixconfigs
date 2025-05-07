let
  sources = import ../npins;
  pkgs = import sources.nixpkgs { };
  lib = pkgs.lib;

  hive = import ./hive.nix;

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

  nodes = lib.filterAttrs isEligible hive.nodes;

  mkOutput =
    v:
    let
      config = v.config;
    in
    {
      nix-package = config.nix.package;
      nixos-system = config.system.build.toplevel;
      disko-script = config.system.build.diskoScriptNoDeps; # TODO: expose format&mount scripts 
    };
in
# mkOutput = (name: value: mkValue value.config);
lib.mapAttrs (_: mkOutput) nodes
