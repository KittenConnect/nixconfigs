{lib, ...}: {
  imports = [
    ./nixConfig.nix
    ./nixHome.nix
    ./base.nix
    ./misc.nix

    ./disko
    ./packages

    ./wireguard
    ./firewall.nix
    ./loopback0.nix
    ./vrfs.nix
    ./bird2
  ];

  options.kittenModules.common = lib.mkEnableOption "Kitten common basic configurations";
}
