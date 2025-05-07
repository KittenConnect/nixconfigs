args@{ pkgs, ... }:
{
  strings = import ./strings.nix args;
  peers = import ./peers.nix args;
  #attrsets = import ./attrsets.nix args;
  #options = import ./options.nix args;
}
