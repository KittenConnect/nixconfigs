let
  pkgConfig = {
   allowUnfree = true;
  };

  sources = import ./npins;

  pkgs = import sources.nixpkgs { config = pkgConfig; };

  inherit (pkgs) lib;

  hosts = import ./hosts ({ inherit pkgs lib; });

  defConf = {
    meta = {
      specialArgs = {
        inherit sources pkgConfig;
      };

      nixpkgs = pkgs;

      # You can also override Nixpkgs by node!
      # nodeNixpkgs = {
      #   node-b = ./another-nixos-checkout;
      # };

      # If your Colmena host has nix configured to allow for remote builds
      # (for nix-daemon, your user being included in trusted-users)
      # you can set a machines file that will be passed to the underlying
      # nix-store command during derivation realization as a builders option.
      # For example, if you support multiple orginizations each with their own
      # build machine(s) you can ensure that builds only take place on your
      # local machine and/or the machines specified in this file.
      # machinesFile = ./machines.client-a;
    };

    defaults = import ./hosts/_defaults.nix;

  };
in
lib.foldl' (
  acc: profile:
  let
    configs = hosts.${profile};
  in
  (lib.mapAttrs (
    n: value:
    (
      args@{
        name,
        nodes,
        pkgs,
        ...
      }:
      value (args // { inherit profile; }) // { networking.hostName = name; }
    )
  ) configs)
  // acc
) defConf (lib.attrNames hosts)
