{ ... }:
let
  defaultPeers = import ../../_peers { };
in
defaultPeers
// {

  # Transit
  # TRS_virtua6_RS01 = import ./TRS-virtua6-RS01.nix { };
  # TRS_virtua6_RS02 = import ./TRS-virtua6-RS02.nix { };

  # # Internal Tunnels
  KIT_IG1_RTR = import ./KIT-IG1-RTR.nix { };
  # virtuaNix_PAR = import ./KIT-VIRTUA-EDGE.nix { };
  # vultrNix_PAR = import ./KIT-VULTR-EDGE.nix { };
  # # LGC_virtua_PAR = import ./KIT-VIRTUA-EDGE.legacy.nix { };

  # toinuxMEL1 = import ./KIT-toinux-MEL1.nix { };
  # roumainNTE = import ./KIT-roumain-NTE.nix { };
}
