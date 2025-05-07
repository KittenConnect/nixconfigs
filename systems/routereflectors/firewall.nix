{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.hostprofile.rr;
in
{

  config = {

    # environment.systemPackages = with pkgs; [ ferm ]; # Prepare an eventual switch to FERM

    networking.nftables.enable = true;

    # Open ports in the firewall.
    networking.firewall = {
      enable = true;

      allowedTCPPorts = [
        22 # SSH
        179 # BGP
        1790 # Internal BGP
      ];
      # allowedUDPPorts = [ ... ];

      # checkReversePath = "loose";
      checkReversePath = false;

      filterForward = false;
    };
  };
}
