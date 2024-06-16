# {
#   clients = import ./clients { };
#   miscservers = import ./miscservers { };

#   homerouters = import ./homerouters { };
#   routers = import ./routers { };
#   routereflectors = import ./routereflectors { };

#   stonkmembers = import ./stonkmembers { };
# }

args@{ lib, ... }:
let
  blacklist = [

  ];

  filterFunc = (
    n: v:
    v == "directory"

    && !lib.hasPrefix "_" n
    && !builtins.elem n blacklist
  );

  folders = builtins.attrNames (lib.filterAttrs filterFunc (builtins.readDir ./.));
in
lib.genAttrs folders (folder: (import (./. + "/${folder}") (args // { })))
