args @ {
  pkgs,
  lib,
  ...
}: {
  strings = import ./strings.nix args;
  peers = import ./peers.nix args;

  types = {
    inherit (import ./file-type.nix args) fileType;
  };
  #attrsets = import ./attrsets.nix args;
  #options = import ./options.nix args;
}
