{ kittenLib, ... }:
kittenLib.peers {
  host = ./.;
  profile = ../..;

  blacklist = [ "KIT-ROMAIN-EDGE.legacy" ];
  manual = {
    # Transit
    TRS_romain6_RS01 = ./TRS-romain6-RS01.nix;

    # Internal Tunnels
    KIT_IG1_RTR = ./KIT-IG1-RTR.nix;
  };
}
