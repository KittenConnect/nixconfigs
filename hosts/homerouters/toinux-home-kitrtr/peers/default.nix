# // {

#   # Transit
#   # TRS_virtua6_RS01 = import ./TRS-virtua6-RS01.nix { };
#   # TRS_virtua6_RS02 = import ./TRS-virtua6-RS02.nix { };

#   # # Internal Tunnels
#   # virtuaNix_PAR = import ./KIT-VIRTUA-EDGE.nix { };
#   # vultrNix_PAR = import ./KIT-VULTR-EDGE.nix { };
#   # # LGC_virtua_PAR = import ./KIT-VIRTUA-EDGE.legacy.nix { };

#   # aureG8 = import ./KIT-aurelien-RBR.nix { };
#   # toinuxMEL1 = import ./KIT-toinux-MEL1.nix { };
#   # roumainNTE = import ./KIT-roumain-NTE.nix { };
# }
args@{ lib, ... }:
let
  blacklist = [ ];

  defaultPeers = import ../../_peers { };

  peers = builtins.attrNames (
    lib.filterAttrs (
      n: v:
      n != "default.nix"
      && lib.hasSuffix ".nix" n
      && !lib.hasPrefix "_" n
      && !lib.hasPrefix "." n
      && !builtins.elem (lib.removeSuffix ".nix" n) blacklist
    ) (builtins.readDir ./.)
  );
in
defaultPeers // (lib.genAttrs peers (peer: (import (./. + "/${peer}") (args // { }))))
