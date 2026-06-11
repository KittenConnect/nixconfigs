{
  lib,
  pkgs,
  config,
  targetProfile,
  ...
}:
let
  cfg = config.hostprofile.${targetProfile};
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
      ];
      # allowedUDPPorts = [ ... ];

      # checkReversePath = "loose";
      checkReversePath = true;

      filterForward = false;
    };
  };
}
