# args@{ lib, ... }:
# let
#   blacklist = [ ];

#   folders = builtins.attrNames (
#     lib.filterAttrs (n: v: v == "directory" && !lib.hasPrefix "_" n && !builtins.elem n blacklist) (
#       builtins.readDir ./.
#     )
#   );
# in
# lib.genAttrs folders (folder: (import (./. + "/${folder}") (args // { })))
{...}: {}