args@{ pkgs, ... }:
{
  strings = import ./strings.nix args;
  #attrsets = import ./attrsets.nix args;
  #options = import ./options.nix args;
}
