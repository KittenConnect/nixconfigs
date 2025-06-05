let
  inherit ((import ./. {}).inputs)
    sources
    pkgs
    lib
    kittenLib
    hosts
    hostsDefaults
    pkgsConfig
    ;

  defConf = {
    meta = {
      specialArgs = {
        inherit kittenLib sources pkgsConfig;
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

    defaults = hostsDefaults;
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

        customConfig =
          config:
          config
          // {
            networking = (config.networking or { }) // {
              hostName = name;
            };

            sops = (config.sops or { }) // {
              defaultSopsFile = ./secrets/${name}.yaml;
            };
          };
      in
      customConfig v
    )
  ) configs)
) defConf (lib.attrNames hosts)
