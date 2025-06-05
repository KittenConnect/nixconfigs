{ pkgs, lib }:
systemName: systemConfig:
pkgs.writeShellApplication {
  name = "nixos-anywhere";

  runtimeInputs = [ systemConfig.config.nix.package ] ++ (with pkgs; [ nixos-anywhere ]);

  text =
    let
      inherit (lib) optionalString;
      inherit (builtins) toString toJSON;

      username = systemConfig.config.deployment.targetUser;
      userStr = optionalString hasUser "${username}@";
      hasUser = username != "" && username != null;

      hasHost = hostname != "" && hostname != null;
      hostname = systemConfig.config.deployment.targetHost;

      hasPort = port != "" && port != null;
      portStr = optionalString hasPort ":${toString port}";
      port = systemConfig.config.deployment.targetPort;

      hasOptions = options != [ ];
      options = systemConfig.config.deployment.sshOptions;

      destination = optionalString hasHost "${userStr}${hostname}${portStr}";
    in
    ''
      command -v nixos-anywhere
      command -v nix
      nix --version

      echo "will install ${systemName} -> ${destination}"

      set -x
      [[ $# -gt 0 ]] || set -- ${if hasHost then destination else "--help"}

      # TODO: use mount script or diskoScript depending on some usefull criterias
      # exec nixos-anywhere -- --option show-trace true --flake ''${self.outPath}#''${confName} $@
      exec nixos-anywhere --store-paths "${systemConfig.config.system.build.diskoScriptNoDeps}" "${systemConfig.config.system.build.toplevel}" "$@"
    '';
}
# )
# (
#   lib.filterAttrs (
#     n: v: v.config.system.build ? diskoScriptNoDeps
#   ) (import ./_makeHive.nix (import ../hive.nix)).nodes
# )
