{ kittenLib, ... }:
kittenLib.peers {
  host = ./.;
  profile = ../..;

  blacklist = [ "KIT-VIRTUA-EDGE.legacy" ];
  manual = {
    # Transit
    TRS_virtua6_RS01 = ./TRS-virtua6-RS01.nix;
    TRS_virtua6_RS02 = ./TRS-virtua6-RS02.nix;

    # Internal Tunnels
    KIT_IG1_RTR = ./KIT-IG1-RTR.nix;
    vultrNix_PAR = ./KIT-vultr-edge.nix;
    # LGC_virtua_PAR = ./KIT-VIRTUA-EDGE.legacy.nix;
  };
}
