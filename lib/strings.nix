args@{ pkgs, lib, ... }:
let
  inherit (lib)
    concatMapStrings
    concatStringsSep
    splitString
    range
    ;
in
rec {
  spaces = n: concatMapStrings (x: " ") (range 1 n);
  indentedLines = n: s: concatStringsSep "\n${spaces n}" (splitString "\n" s);
  quotedString = x: ''"${x}"'';
}
