let
  sources = import ../npins;

  pkgs = import sources.nixpkgs { };
  lib = pkgs.lib;
in
pkgs.writeShellApplication {
  name = "colmena";

  runtimeInputs = with pkgs; [
    colmena
    lix
  ];

  text = let sshconfig = ../sshconfig; in ''
    command -v colmena
    command -v nix
    nix --version

    echo "Will run colmena"
    set -x
    [[ $# -gt 0 ]] || set -- --help
    export SSH_CONFIG_FILE=${sshconfig}
    exec colmena "$@"
  '';
}
