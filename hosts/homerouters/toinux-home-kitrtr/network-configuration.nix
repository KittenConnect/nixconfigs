{ ... }:
{
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  networking = {
    #nameservers = [ "1.3.3.7" ];

    # vlans = {
    #   vlanXX = {
    #     id = XX;
    #     interface = "xxx";
    #   };
    # };

    interfaces = {
      ens18.useDHCP = true;

      # vlanXX = {

      #   # ipv4.addresses = [
      #   #   {
      #   #     address = "xxx.xx.xx.xx";
      #   #     prefixLength = 24;
      #   #   }
      #   # ];

      #   # ipv6.addresses = [
      #   #   {
      #   #     address = "2a13:79c0:ffff:feff:b00b::xxx";
      #   #     prefixLength = 112;
      #   #   }
      #   # ];
      # };
    };

    # defaultGateway = {
    #   address = "xx.xx.xx.xx";
    #   metric = 42;
    #   interface = iface;
    # };

    # defaultGateway6 = {
    #   address = "fe80::1";
    #   metric = 42;
    #   interface = iface;
    # };

    useDHCP = false;
    #dhcpcd.enable = false;
  };

  systemd.network.enable = true;
}
