{ lib, ... }:
let
  iface = "enp1s0";
  # kittenIFACE = "ens19";
in
{
  kittenModules = {
    bird = {
      transitInterfaces = [ iface ];
      static6 = lib.mapAttrsToList (n: v: ''${n} via "fe80::${v}%${iface}"'') { 
        "2001:19f0::/32" = "fc00:4ff:fe82:5c6e"; 
      };
      
      # [
      #   ''2001:19f0:ffff::1/128 via "${vultrMAC}%${iface}"'' # Vultr bgp neighbor
      # ];
    };
  };

  services.cloud-init = {
    enable = true;
    ext4.enable = true;
    network.enable = true;
    settings = {
      datasource_list = [ "Vultr" ];
      disable_root = false;
      ssh_pwauth = 0;
      updates = {
        network = {
          when = [
            "boot"
            "boot-legacy"
            "boot-new-instance"
            "hotplug"
          ];
        };
      };
    };
  };

  networking.useDHCP = false;
  systemd.network.enable = true;
}
