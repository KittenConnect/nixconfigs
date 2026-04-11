{ kittenLib, ... }:
kittenLib.peers {
  host = ./.;
  profile = ../..;

  blacklist = [ "KIT-VULTR-EDGE.legacy" ];
  manual = {
    # Transit
    TRS_vultr6_RTR = ./TRS-vultr6-RTR.nix;

    # Internal Tunnels
    KIT_IG1_RTR = ./KIT-IG1-RTR.nix;
    virtuaNix_PAR = ./KIT-virtua-edge.nix;
    # LGC_virtua_PAR = ./KIT-VIRTUA-EDGE.legacy.nix;
  };
}
