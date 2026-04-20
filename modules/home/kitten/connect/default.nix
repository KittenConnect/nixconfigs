{lib, ...}: {
  imports = [
    ./base.nix
    ./misc.nix
    ./kube.nix
    ./zsh.nix
  ];

  options.kittenHome.common = lib.mkEnableOption "Kitten common basic configurations";
}
