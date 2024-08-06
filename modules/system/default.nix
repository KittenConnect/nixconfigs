{ ... }:
{
  imports = [
    ./kitten/connect/nixConfig.nix
    ./kitten/connect/packages.nix
    ./kitten/connect/firewall

    ./kitten/connect/wireguard
    ./kitten/connect/loopback0.nix
    ./kitten/connect/bird2
  ];
}
