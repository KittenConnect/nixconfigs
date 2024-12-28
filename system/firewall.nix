{ lib, ... }:
{
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # TODO: Re-enable when tailscale is compatible
  #       -> Warning: XT target MASQUERADE not found
  # networking.nftables.enable = true; # Cleaner approach, easier rules implementation 

  networking.firewall = {
    enable = lib.mkDefault false; # TODO: Enable IT

    allowedTCPPorts = [
      22
      # 80
      # 443
    ];

    # allowedUDPPortRanges = [
    #   { from = 4000; to = 4007; }
    #   { from = 8000; to = 8010; }
    # ];
  };
}
