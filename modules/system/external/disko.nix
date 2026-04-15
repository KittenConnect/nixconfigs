{sources ? ((import ../../.. {}).inputs).sources, ...}: {
  imports = [
    "${sources.disko}/module.nix"
  ];
}
