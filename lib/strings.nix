args @ {
  pkgs,
  lib,
  ...
}: let
  inherit
    (lib)
    concatMapStrings
    concatStringsSep
    splitString
    range
    ;
in rec {
  spaces = n: concatMapStrings (x: " ") (range 1 n);
  # indentedLines = n: s: concatStringsSep "\n${spaces n}" (splitString "\n" s);

  asLinesArray = lines:
    if builtins.isList lines
    then lines
    else if builtins.isString lines
    then lib.splitString "\n" lines
    else throw "this function needs to be called with str or list of strs";

  indentedLines = level: lines: let
    indentSize = 2; # Space number
    prefix = builtins.concatStringsSep "" (builtins.genList (x: " ") (level * indentSize));
  in
    (lib.concatMapStringsSep "\n" (line: "${prefix}${line}") (asLinesArray lines))
    + (lib.optionalString (lib.hasSuffix "\n" lines) "\n");

  quotedString = x: ''"${x}"'';
}
