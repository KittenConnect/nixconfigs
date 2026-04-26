{ inputs ? ((import ../../.. {}).inputs), pkgsSources ? inputs.pkgsInstances.nixos, kittenLib ? inputs.kittenLib, ...}: {
  imports = [
    "${pkgsSources.home-manager}/nixos"
  ];

  config = {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    # Optionally, use home-manager.extraSpecialArgs to pass arguments to home.nix
    home-manager.extraSpecialArgs = {
      inherit kittenLib;
    };
  };
}
