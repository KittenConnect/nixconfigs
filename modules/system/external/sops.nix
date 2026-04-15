{sources ? ((import ../../.. {}).inputs).sources, ...}: {
  imports = [
    "${sources.sops-nix}/modules/sops"
  ];
}
