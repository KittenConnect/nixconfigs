{...}: let
  inherit ((import ../.. {}).inputs) sources;
in {
  imports = [
    "${sources.homefiles}"

    ./kitten/connect/kube.nix
  ];

  disabledModules = [ 
    "${sources.homefiles}/home/zsh.nix"
    "${sources.homefiles}/home/ssh.nix"
  ];
}
