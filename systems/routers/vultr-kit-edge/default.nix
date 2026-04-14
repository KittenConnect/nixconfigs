# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
args @ {
  config,
  kittenLib,
  lib,
  pkgs,
  ...
}: let
  diskoProfile = "simple";
  diskoConfig = {
    bootdisk = "/dev/vda";
    # swapSize = 1024;
  };

  iface = "enp1s0";

  peers = import ./peers args;

  wgPeers = (
    lib.mapAttrs (n: v: v.wireguard) (lib.filterAttrs (n: v: v ? wireguard && v.wireguard != {}) peers)
  );

  birdPeers = lib.mapAttrs (n: v: builtins.removeAttrs v ["wireguard"]) peers;
in {
  imports = [
    ./hardware-configuration.nix
    #     ./network-configuration.nix # included here because of its simplicity

    ../../../modules/system/kitten/connect/bird2/snippets/kittenCores.nix
  ];

  deployment = {
    # Disable SSH deployment. This node will be skipped in a
    # normal`colmena apply`.
    targetUser = "root";
    targetHost = null; # TODO: implement
  };

  # Bootloader.
  boot.loader.grub.efiSupport = false;
  boot.loader.grub.enable = true;

  # Networking

  services.cloud-init = {
    enable = true;
    ext4.enable = true;
    network.enable = true;
    settings = {
      datasource_list = ["Vultr"];
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

  kittenModules = {
    disko = {
      enable = true;
      profile = diskoProfile;

      ${diskoProfile} = diskoConfig;
    };

    # loopback0 = {
    #   enable = true;
    #   ipv6 = [ "2a13:79c0:ffff:fefe::12:10" ];
    # };

    bird = {
      enable = true;

      loopback6 = "2a13:79c0:ffff:fefe::b48d";

      transitInterfaces = [iface];
      static6 =
        [
          "2a13:79c0:ffff:fefe::b00b/128 unreachable" # Special Anycast "loopback" for default gateways

          # "2a13:79c0:ffff::/48 unreachable" # Networking stuff
          # "2a13:79c0:ffff:fefe::/64 unreachable" # LoopBacks
          # "2a13:79c0:ff00::/40 unreachable" # full range /40
          "2a12:5844:1310::/44 unreachable" # New range /44
        ]
        ++ lib.mapAttrsToList (n: v: ''${n} via "fe80::${v}%${iface}"'') {
          "2001:19f0::/32" = "fc00:4ff:fe82:5c6e";
        };

      peers = birdPeers;
    };

    wireguard = {
      enable = true;
      # defaultIFACE = "ens18";
      peers = wgPeers;
    };

    firewall = {
      forward = {
        enable = true;
        keepInvalidState = true;
        # rules = ''
        #   # iifname "''${kittenIFACE}" ip6 saddr 2a13:79c0:ffff:feff:b00b:caca:b173:0/112 oifname $wireguardIFACEs counter accept
        #   iifname $wireguardIFACEs ip6 daddr 2a13:79c0:ffff:fefe::113:91 tcp dport { 179, 1790 } counter accept
        #   oifname bootstrap ip6 daddr 2a13:79c0:ffff:feff:b00b:3965:222:0/112 counter accept

        #   ip6 saddr 2a01:cb08:bbb:3700::/64 oifname ens19 counter accept

        #   iifname ens19 oifname $wireguardIFACEs counter accept
        # '';
        natRules = ''
          oifname "${iface}" ip6 saddr 1010:cafe:ffff:feff::/64 snat ip6 prefix to 2a12:5844:1311:feff::/64
          oifname "${iface}" ip6 saddr 2a13:79c0:ffff:fefe::/64 snat ip6 prefix to 2a12:5844:1311:fefe::/64
        '';
      };
    };
  };

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  nixpkgs.config.allowUnfree = true;
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

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
  system.stateVersion = "23.11"; # Did you read the comment?
}
