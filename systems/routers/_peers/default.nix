args @ {...}: let
  globalPeers = import ../../_peers args;
in {
  # Internal RR
  inherit (globalPeers) IG1_RR91;
}
