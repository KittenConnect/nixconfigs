let
  sources = import ../npins;

  pkgs = import sources.nixpkgs { };
  lib = pkgs.lib;
in
lib.mapAttrs
  (
    name: value:
    pkgs.writeShellApplication {
      name = "nixos-anywhere";

      runtimeInputs = [ value.config.nix.package ] ++ (with pkgs; [ nixos-anywhere ]);

      text =
        let
          inherit (lib) optionalString;
          inherit (builtins) toString toJSON;

          username = value.config.deployment.targetUser;
          userStr = optionalString hasUser "${username}@";
          hasUser = username != "" && username != null;

          hasHost = hostname != "" && hostname != null;
          hostname = value.config.deployment.targetHost;

          hasPort = port != "" && port != null;
          portStr = optionalString hasPort ":${toString port}";
          port = value.config.deployment.targetPort;

          hasOptions = options != [ ];
          options = value.config.deployment.sshOptions;

          destination = optionalString hasHost "${userStr}${hostname}${portStr}";
        in
        ''
          command -v nixos-anywhere
          command -v nix
          nix --version

          echo "will install ${name} -> ${destination}"

          set -x
          [[ $# -gt 0 ]] || set -- ${if hasHost then destination else "--help"}

          # exec nixos-anywhere -- --option show-trace true --flake ''${self.outPath}#''${confName} $@
          exec nixos-anywhere --store-paths "${value.config.system.build.diskoScriptNoDeps}" "${value.config.system.build.toplevel}" "$@"
        '';
    }
  )
  (
    lib.filterAttrs (
      n: v: v.config.system.build ? diskoScriptNoDeps
    ) (import ./_makeHive.nix (import ../hive.nix)).nodes
  )
