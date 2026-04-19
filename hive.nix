let
  inherit ((import ./. { }).inputs)
    sources
    pkgsInstances
    pkgs
    lib
    kittenLib
    hosts
    hostsDefaults
    pkgsConfig
    ;

  defConf = {
    meta =
      let
        nodeNixpkgs = {
          goog-kit-rtr = pkgsInstances.nixos2511;
        };
      in
      {
        specialArgs = {
          inherit kittenLib sources pkgsConfig;
          pkgsSources = pkgs.kittenSources;
        };

        nixpkgs = pkgs;

        # You can also override Nixpkgs by node!
        inherit nodeNixpkgs;

        nodeSpecialArgs = lib.mapAttrs (n: v: {
          pkgsSources = v.kittenSources;
        }) nodeNixpkgs;

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
        config = value (args // { inherit profile; });

        customModule = {
          networking.hostName = lib.mkForce name;
          sops.defaultSopsFile = ./.secrets/${name}.yaml;
        };
      in
      config
      // {
        imports = (config.imports or [ ]) ++ [ customModule ];
      }
    )
  ) configs)
) defConf (lib.attrNames hosts)
