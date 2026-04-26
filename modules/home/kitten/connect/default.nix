{lib, ...}: {
  imports = [
    ./base.nix
    ./misc.nix
    ./kube.nix
    ./zsh.nix
  ];

  options.kittenHome.common = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Kitten common basic configurations";
  };
}
