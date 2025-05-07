let
  pkgConfig = {
    allowUnfree = true;
  };

  sources = import ./npins;
  
  pkgs = import sources.nixpkgs { config = pkgConfig; };
  inherit (pkgs) lib;

  kittenLib = import ./lib { inherit pkgs lib; };

  hosts = import ./systems { inherit pkgs lib; };

  defConf = {
    meta = {
      specialArgs = {
        inherit kittenLib sources pkgConfig;
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

    defaults = import ./systems/_defaults.nix;

  };
in
lib.foldl' (
  acc: profile:
  let
    configs = hosts.${profile};
  in
  acc
  // (lib.mapAttrs (
    n: value:
    (
      args@{
        name,
        nodes,
        pkgs,
        ...
      }:
      let
        v = (value (args // { inherit profile; }));
      in
      v
      // {
        networking = (v.networking or { }) // {
          hostName = name;
        };
        sops = (v.sops or { }) // {
          defaultSopsFile = ./secrets/${name}.yaml;
        };
      }
    )
  ) configs)
) defConf (lib.attrNames hosts)
