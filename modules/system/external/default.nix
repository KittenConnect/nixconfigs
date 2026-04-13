{...}: {
  # Default nixOS modules

  imports = [
    ./disko.nix
    ./sops.nix
    ./home-manager.nix
  ];
}
