args@{ lib, ... }:
let
  # sources = import ../npins;

  inherit (builtins) readDir filter;
  inherit (lib.strings) hasPrefix hasSuffix;
  inherit (lib.attrsets) filterAttrs attrNames;

  isFile = n: v: v == "regular";
  
  overlaysPath = ./.;
  files = attrNames (filterAttrs isFile (readDir overlaysPath));

  filterFunc = file: file != "default.nix" && hasSuffix ".nix" file && !hasPrefix "_" file;
  overlays = map (file: import (overlaysPath + "/${file}")) (filter filterFunc files);

  # baseConfig = import ./nixpkgs.config.nix;
in
overlays
# {
#   inherit overlaysPath overlays baseConfig sources;
# }
