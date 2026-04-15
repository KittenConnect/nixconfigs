{sources ? ((import ../../.. {}).inputs).sources, ...}: {
  imports = [
    "${sources.home-manager}/nixos"
  ];

  config = {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    # Optionally, use home-manager.extraSpecialArgs to pass arguments to home.nix
  };
}
