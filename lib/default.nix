args @ {
  pkgs,
  lib,
  ...
}: {
  strings = import ./strings.nix args;
  params = import ./params args;
  peers = import ./peers.nix args;

  types = {
    inherit (import ./file-type.nix args) fileType;
  };
  #attrsets = import ./attrsets.nix args;
  #options = import ./options.nix args;
}
