{ lib, ... }:
let
  blacklist = [
    "stonkmembers"
  ];

  filterFunc = (
    n: v:
    v == "directory"

    && !lib.hasPrefix "_" n
    && !builtins.elem n blacklist
  );

  folders = builtins.attrNames (lib.filterAttrs filterFunc (builtins.readDir ./.));
in
lib.genAttrs folders (
  folder:
  (
    let
      configs = builtins.attrNames (lib.filterAttrs filterFunc (builtins.readDir (./. + "/${folder}")));
    in
    lib.genAttrs configs (confName: (import (./. + "/${folder}/${confName}")))
  )
)
