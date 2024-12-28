args@{ lib, ... }:
let
  inherit (builtins) readDir filter;
  inherit (lib.strings) hasPrefix hasSuffix;
  inherit (lib.attrsets) filterAttrs attrNames;

  isFile = n: v: v == "regular";
  files = attrNames (filterAttrs isFile (readDir ./.));

in
{
  imports = map (file: ./. + "/${file}") (
    filter (file: file != "default.nix" && hasSuffix ".nix" file && !hasPrefix "_" file) files
  );
}
