{...}: let inherit ((import ../../.. {}).inputs) sources; in
{
  imports = [
    "${sources.disko}/module.nix"
  ];
}
