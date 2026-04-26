let
  withSources = instanceSources: (final: prev: {kittenSources = builtins.removeAttrs instanceSources ["nixpkgs"];});
in
  {
    sources ? import ./npins,
    nixpkgs ? pkgsSources.nixpkgs,
    pkgsSources ? import (./npins + "/${pkgsInstance}"),
    pkgsInstance ? "nixos2511",
    pkgs' ? import nixpkgs {},
    pkgsConfig ? import ./pkgs.config.nix,
    pkgsOverlays ? import ./overlays,
    pkgs ?
      import nixpkgs {
        config = pkgsConfig;
        overlays = pkgsOverlays ++ [(withSources pkgsSources)];
      },
    lib ? pkgs.lib,
    hostsDefaults ? import ./systems/configuration.nix,
    hosts ? (
      import ./systems {
        inherit pkgs lib;
      }
    ),
    kittenLib ? (
      import ./lib {
        inherit pkgs lib;
      }
    ),
    self ? lib.cleanSource ./.,
    ...
  }: let
    # Flake-Less repository entrypoint
    inputs = {
      inherit pkgs lib;

      sources = let
        selfSource = builtins.fetchGit {
          url = ./.;
          shallow = true;
        };
      in
        sources
        // {
          self = rec {
            branch = "HEAD";
            hash = selfSource.narHash;
            inherit (selfSource) outPath;
            repository = {
              type = "GitHub";
              owner = "kittenconnect";
              repo = "nixconfigs";
            };
            revision = selfSource.dirtyRev or selfSource.rev;
            type = "Git";
            url = "https://github.com/${repository.owner}/${repository.repo}/archive/${revision}.tar.gz";
          };
        };

      pkgsInstances = let
        mkInstance = n: let
          instanceSources = import (./npins + "/${n}");
        in (import instanceSources.nixpkgs {
          config = pkgsConfig;
          overlays = pkgsOverlays ++ [(withSources instanceSources)];
        }); # // {kittenSources = builtins.removeAttrs instanceSources ["nixpkgs"];};
      in
        lib.mapAttrs' (n: v: lib.nameValuePair (lib.replaceStrings ["."] [""] n) (mkInstance n)) (
          lib.filterAttrs (n: v: v == "directory" && builtins.pathExists (./npins + "/${n}/default.nix")) (
            builtins.readDir ./npins
          )
        )
        // {
          nixos = inputs.pkgsInstances.${pkgsInstance};
        };

      inherit
        nixpkgs
        pkgsConfig
        kittenLib
        hosts
        hostsDefaults
        ;

      hive = inputs.usefullFunctions.colmena.makeHive (import ./hive.nix);

      usefullFunctions = {
        makeDynamicScripts = {
          nixosSomewhere = import ./scripts/nixos-anywhere.sh.nix {
            inherit pkgs lib;
            inherit (pkgs) nixos-anywhere;
          };
          nixosBurnImage = import ./scripts/nixos-burnimage.sh.nix {
            inherit pkgs lib;
            inherit (pkgs) pv;
          };
          nixosGoogleCompute = import ./scripts/gcloud-deploy.sh.nix {
            inherit pkgs lib;
            inherit (pkgs) google-cloud-sdk;
          };
        };

        colmena = {
          makeHive = rawHive:
            (import "${sources.colmena}/src/nix/hive/eval.nix") {
              inherit rawHive;

              colmenaOptions = import "${sources.colmena}/src/nix/hive/options.nix";
              colmenaModules = import "${sources.colmena}/src/nix/hive/modules.nix";
            };
        };

        # filterThings = lib.filterAttrs (
        #   n: v: v.config.system.build ? diskoScriptNoDeps
        # ) (inputs.usefullFunctions.colmena.makeHive (import ../hive.nix)).nodes;
      };
    };
  in rec {
    inherit inputs;

    outputs = let
      inherit (inputs) usefullFunctions;

      byMachines = lib.mapAttrs (_: f: lib.mapAttrs f inputs.hive.nodes);
    in {
      nixosConfigurations = inputs.hive.nodes;
      packages =
        {
          inherit (pkgs) nixos-anywhere;
        }
        // (byMachines {
          nixosSomewhere = usefullFunctions.makeDynamicScripts.nixosSomewhere;
          nixosBurnImage = usefullFunctions.makeDynamicScripts.nixosBurnImage;
        });

      # {
      #   # Executed by `nix flake check`
      #   checks."<system>"."<name>" = derivation;
      #   # Executed by `nix build .#<name>`
      #   packages."<system>"."<name>" = derivation;
      #   # Executed by `nix build .`
      #   packages."<system>".default = derivation;
      #   # Executed by `nix run .#<name>`
      #   apps."<system>"."<name>" = {
      #     type = "app";
      #     program = "<store-path>";
      #   };
      #   # Executed by `nix run . -- <args?>`
      #   apps."<system>".default = { type = "app"; program = "..."; };

      #   # Formatter (alejandra, nixfmt or nixpkgs-fmt)
      #   formatter."<system>" = derivation;
      #   # Used for nixpkgs packages, also accessible via `nix build .#<name>`
      #   legacyPackages."<system>"."<name>" = derivation;
      #   # Overlay, consumed by other flakes
      #   overlays."<name>" = final: prev: { };
      #   # Default overlay
      #   overlays.default = final: prev: { };
      #   # Nixos module, consumed by other flakes
      #   nixosModules."<name>" = { config, ... }: { options = {}; config = {}; };
      #   # Default module
      #   nixosModules.default = { config, ... }: { options = {}; config = {}; };
      #   # Hydra build jobs
      #   hydraJobs."<attr>"."<system>" = derivation;
      #   # Used by `nix flake init -t <flake>#<name>`
      #   templates."<name>" = {
      #     path = "<store-path>";
      #     description = "template description goes here?";
      #   };
      #   # Used by `nix flake init -t <flake>`
      #   templates.default = { path = "<store-path>"; description = ""; };
      # }

      devShells = {
        default = outputs.devShells.legacy;

        legacy = pkgs.mkShell {
          shellHook = ''
            # TODO: implement alias for nixos-anywhere
            # nixos-anywhere() {
            #
            # }
            alias nixos-anywhere='nix run -f ${inputs.sources.self}/_scripts/nixos-anywhere.nix'

            export GCP_OSLOGIN_USER=$(gcloud compute os-login describe-profile --format=json | jq -r '.posixAccounts[] | .username')
          '';

          nativeBuildInputs = with pkgs; [
            act
            sops
            # nixel
            alejandra
            colmena
            google-cloud-sdk
            jq
            npins
          ];
        };
      };
      #   # Used by `nix develop .#<name>`
      #   devShells."<system>"."<name>" = derivation;
      #   # Used by `nix develop`
      #   devShells."<system>".default = derivation;
    };
  }
