{ kittenLib, ... }:
kittenLib.peers {
  host = ./.;
  profile = ../..;

  blacklist = [ ];
  manual = {
    # Internal Tunnels
    virtuaNix_PAR = ./KIT-VIRTUA-EDGE.nix;
    vultrNix_PAR = ./KIT-VULTR-EDGE.nix;
    # LGC_virtua_PAR = ./KIT-VIRTUA-EDGE.legacy.nix;

    aureG8 = ./KIT-aurelien-RBR.nix;
    toinuxMEL1 = ./KIT-toinux-MEL1.nix;
    roumainNTE = ./KIT-roumain-NTE.nix;
    roumaiNixNTE = ./KIT-roumainNix-NTE.nix;
  };
}
