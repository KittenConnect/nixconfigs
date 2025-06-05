{
  sources ? import ./npins,
  _pkgsConfig ? (import ./nixpkgs.config.nix),
  pkgsConfig ? { },
  nixpkgs ? sources.nixpkgs,
  pkgs ? import nixpkgs (_pkgsConfig // pkgsConfig),

  hostsDefaults ? import ./systems/_defaults.nix,
  hosts ? (
    import ./systems {
      inherit pkgs;
      inherit (pkgs) lib;
    }
  ),
  kittenLib ? (
    import ./lib {
      inherit pkgs;
      inherit (pkgs) lib;
    }
  ),
  ...
}:
let
  inherit (pkgs) lib;

  # Flake-Less repository entrypoint

  pkgsConfig' = _pkgsConfig // pkgsConfig;

  inputs = {
    inherit
      sources
      nixpkgs
      pkgs
      kittenLib
      hosts
      hostsDefaults
      ;

    self = lib.cleanSource ./.;

    hive = inputs.usefullFunctions.colmena.makeHive (import ./hive.nix);

    usefullFunctions = {
      makeDynamicScripts = {
        nixosSomewhere = import ./scripts/nixos-anywhere.sh.nix { inherit pkgs lib; };
      };

      colmena = {
        makeHive =
          rawHive:
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

    pkgsConfig = pkgsConfig';
    inherit (pkgs) lib;
  };
in rec {
  inherit inputs;

  outputs =
    let
      inherit (inputs) usefullFunctions;
      nixosConfigurations = inputs.hive.nodes;

      byMachines = lib.mapAttrs (_: f: lib.mapAttrs f nixosConfigurations);
    in {
      packages =
        {
          inherit (pkgs) nixos-anywhere;
        }
        // (byMachines {
          nixosSomewhere = usefullFunctions.makeDynamicScripts.nixosSomewhere;
        });
      # {
      #   nixos-anywhere = lib.mapAttrs (
      #     n: v: {
      #       # import nixos-anywhere.sh.nix w/ all sort of stuff
      #     }
      #   );
      # };

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
          # nativeBuildInputs is usually what you want -- tools you need to run
          shellHook = ''
            # TODO: implement alias for nixos-anywhere
            # nixos-anywhere() {
            # 
            # }
            alias nixos-anywhere='nix run -f ${inputs.self}/_scripts/nixos-anywhere.nix'
          '';

          nativeBuildInputs = with pkgs; [
            colmena
            act
            # nixel
            nixfmt-rfc-style
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
