{lib, ...}: {
  imports = [
    ./nixConfig.nix
    ./nixHome.nix
    ./base.nix
    ./misc.nix

    ./disko
    ./packages
    ./security

    ./wireguard
    ./firewall.nix
    ./loopback0.nix
    ./vrfs.nix
    ./bird2
  ];

  options.kittenModules.common = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Kitten common basic configurations";
  };
}
