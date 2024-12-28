{ lib, ... }:
let
  iface = "ens18";
  kittenIFACE = "ens19";
in
{
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  networking = {
    useNetworkd = true;

    nftables.tables."nat" = {
      family = "inet";
      name = "nat";

      content = lib.mkAfter ''
	chain postrouting {
	  type nat hook postrouting priority srcnat; policy accept;
	  ip6 daddr 2a13:79c0:ffff:feff:b00b:3965:222:0/112 oifname "bootstrap" counter masquerade # random,persistent
	}
      '';
    };

    firewall = {
      allowedTCPPorts = [ 51888 ];
      allowedUDPPorts = [ 51888 ];
    };

    #nameservers = [ "1.3.3.7" ];
    interfaces = {
      "${iface}".useDHCP = true;

      "${kittenIFACE}" = {

        # ipv4.addresses = [
        #   {
        #     address = "185.10.17.209";
        #     prefixLength = 24;
        #   }
        # ];

        ipv6.addresses = [
          {
            address = "2a13:79c0:ffff:feff:b00b:3965:113:25";
            prefixLength = 112;
          }
        ];
      };
    };

    # defaultGateway = {
    #   address = "185.10.17.254";
    #   metric = 42;
    #   interface = iface;
    # };
  };
}
