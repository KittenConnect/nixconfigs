{ ... }:
{
  imports = [
    ./kitten/connect/nixConfig.nix
    ./kitten/connect/packages.nix
    ./kitten/connect/misc.nix
    
    ./kitten/connect/firewall
    ./kitten/connect/disko
    ./kitten/connect/packages

    ./kitten/connect/wireguard
    ./kitten/connect/loopback0.nix
    ./kitten/connect/bird2
  ];
  # ./kitten/legacy
}
