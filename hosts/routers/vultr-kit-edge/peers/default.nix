{ ... }:
let
  defaultPeers = import ../../_peers { };
in
defaultPeers
// {
  # Transit
  TRS_vultr6_RTR = import ./TRS-vultr6-RTR.nix { };

  # Internal Tunnels
  KIT_IG1_RTR = import ./KIT-IG1-RTR.nix { };
  # LGC_virtua_PAR = import ./KIT-VIRTUA-EDGE.legacy.nix { };
  LGC_vultr_PAR = import ./KIT-VULTR-EDGE.legacy.nix { };
  virtuaNix_PAR = import ./KIT-virtua-edge.nix { };
}
