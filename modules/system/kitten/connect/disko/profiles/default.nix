args@{ lib, ... }:
let
  inherit (builtins) readDir filter;
  inherit (lib.strings) hasPrefix hasSuffix;
  inherit (lib.attrsets) filterAttrs attrNames;

  isFile = n: v: v == "regular";
  files = attrNames (filterAttrs isFile (readDir ./.));

  filterFunc = file: file != "default.nix" && hasSuffix ".nix" file && !hasPrefix "_" file;
in
{
  imports = map (file: ./. + "/${file}") (
    filter filterFunc files
  );
}
