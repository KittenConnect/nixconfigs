# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
  ];

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Net Basics
  networking.useNetworkd = true;
  systemd.network.enable = true;
  systemd.network.wait-online.enable = false;

  environment.systemPackages = with pkgs; [ gobgp ];

  # List services that you want to enable:
  services.gobgpd = {
    enable = true;
    settings = {
      dynamic-neighbors = [
        {
          config = {
            peer-group = "kitten";
            prefix = "2a13:79c0:ffff:fefe::/64";
          };
        }
        {
          config = {
            peer-group = "kittevpn";
            prefix = "2a13:79c0:ffff:feff::/64";
          };
        }
      ];
      global = {
        config = {
          as = 4242421945;
          local-address-list = [
            "2a13:79c0:ffff:fefe::113:91"
            # "172.23.193.197"
          ];
          router-id = "172.23.193.197";
        };
      };
      peer-groups = [
        {
          afi-safis = [
            {
              config = {
                afi-safi-name = "ipv4-unicast";
              };
            }
            {
              config = {
                afi-safi-name = "ipv6-unicast";
              };
            }
            {
              config = {
                afi-safi-name = "l2vpn-evpn";
              };
            }
          ];
          config = {
            peer-as = 4242421945;
            peer-group-name = "kittevpn";
          };
          route-reflector = {
            config = {
              route-reflector-client = true;
              route-reflector-cluster-id = "172.23.193.197";
            };
          };
        }
        {
          afi-safis = [
            {
              config = {
                afi-safi-name = "ipv4-unicast";
              };
            }
            {
              config = {
                afi-safi-name = "ipv6-unicast";
              };
            }
          ];
          config = {
            peer-as = 4242421945;
            peer-group-name = "kitten";
          };
          route-reflector = {
            config = {
              route-reflector-client = true;
              route-reflector-cluster-id = "172.23.193.197";
            };
          };
        }
      ];
    };
    # autoReload = true;
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
}
