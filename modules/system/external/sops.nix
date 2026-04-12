{...}: let inherit ((import ../../.. {}).inputs) sources; in
{
  imports = [
    "${sources.sops-nix}/modules/sops"
  ];
}
