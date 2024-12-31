{ ... }:
let
  globalPeers = import ../../_peers {};
in
{
  # Internal RR
  inherit (globalPeers) IG1_RR91;
}
