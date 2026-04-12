{...}: let inherit ((import ../.. {}).inputs) sources; in
{
  imports = [
    "${sources.homefiles}"

    ./kitten/connect/kube.nix
  ];
}
