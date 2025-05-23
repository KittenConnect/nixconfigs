# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  lib,
  pkgs,
  targetConfig,
  birdConfig,
  ...
}:
let
  IFACE = if targetConfig ? interface then targetConfig.interface else null;

  transitedNetworks =
    if (birdConfig ? transitNetworks && birdConfig.transitNetworks != null) then
      birdConfig.transitNetworks
    else
      [
        "2a13:79c0:ff00::/44" # Transits Customer ranges: 2a13:79c0:{ff00-ff0f}::/48
        "2a13:79c0:ffff:fefe::/64"
        "2a13:79c0:ffff:feff:b00b::/80"
      ];

  wgPeers = filterAttrs (n: v: v ? wireguard && v.wireguard != { }) birdConfig.peers;

  transitIFACEs =
    [ ]
    ++ lib.optionals (birdConfig.transitInterfaces != [ ]) birdConfig.transitInterfaces;
  # ++ lib.optional (birdConfig ? transitInterface) birdConfig.transitInterface;

  kittenIFACEs = (
    (attrNames wgPeers)
    ++ lib.optionals (birdConfig.allowedInterfaces != [ ]) birdConfig.allowedInterfaces
  );

  inherit (lib)
    mkAfter
    optional
    optionals
    optionalString
    concatStringsSep
    concatMapStringsSep
    attrNames
    filterAttrs
    ;
in
{

  config = {
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;

      "net.ipv4.conf.all.src_valid_mark" = 1;

      # "net.ipv4.conf.default.rp_filter" = 2;
      # "net.ipv4.conf.all.rp_filter" = 2;

      # "net.ipv6.conf.all.keep_addr_on_down" = 1;
      # "net.ipv4.raw_l3mdev_accept" = 1;
      # "net.ipv4.tcp_l3mdev_accept" = 1;
      # "net.ipv4.udp_l3mdev_accept" = 1;
    };

    # environment.systemPackages = with pkgs; [ ferm ]; # Prepare an eventual switch to FERM

    networking.nftables = {
      enable = true;

      tables."nixos-fw".content =
        let
          quoteString = x: ''"${x}"'';

          defines = lib.concatStringsSep "\n" ([
            (optionalString (transitIFACEs != [ ])
              "define transitIFACEs = { ${concatMapStringsSep ", " quoteString transitIFACEs} }"
            )
            (optionalString (
              transitedNetworks != [ ]
            ) "define transitNETs = { ${concatStringsSep ", " transitedNetworks} }")
            (optionalString (wgPeers != { })
              "define wireguardIFACEs = { ${concatMapStringsSep ", " quoteString (attrNames wgPeers)} }"
            )
            (optionalString (kittenIFACEs != [ ])
              "define kittenIFACEs = { ${concatMapStringsSep ", " quoteString kittenIFACEs} }"
            )
          ]);

          extraForwardRules = lib.concatStringsSep "\n" (
            [

              ''
                ${optionalString (transitedNetworks != [ ] && transitIFACEs != [ ] && kittenIFACEs != [ ]) ''
                  # iifname $kittenIFACEs oifname $transitIFACEs counter accept
                  ip6 saddr $transitNETs  iifname $kittenIFACEs  oifname $transitIFACEs  counter accept
                  ip6 daddr $transitNETs  oifname $kittenIFACEs  iifname $transitIFACEs  counter accept
                ''}
                # ip6 daddr 2a13:79c0:ff00::/48 counter accept
                # ip6 daddr { 2a13:79c0:ffff:feff:b00b:3945:a51:b00b, 2a13:79c0:ffff:feff:b00b:3945:a51:dead } counter accept

                # ip6 saddr 2a13:79c0:ffff:feff:b00b::/80 ip6 daddr 2a13:79c0:ffff:fefe::/64 counter accept

                # ip6 saddr { 2a13:79c0:ffff:fefe::/64, 2a13:79c0:ffff:feff::/64 } ip6 daddr { 2a13:79c0:ffff:fefe::/64, 2a13:79c0:ffff:feff::/64 } counter accept


                ${optionalString (kittenIFACEs != [ ]) ''
                  iifname $kittenIFACEs oifname $kittenIFACEs counter accept
                ''}
              ''
            ]

            ++ optional (birdConfig ? extraForwardRules) birdConfig.extraForwardRules

            ++ optional (kittenIFACEs != [ ]) ''
              iifname $kittenIFACEs log prefix "refused connection: " level info reject comment "reject internal instead of drop"
            ''
          );
        in
        mkAfter ''
          # FireWall Test Configs
          ${defines}

            chain forward {
              type filter hook forward priority filter; policy drop;
              # We want StateLess firewalling
              # ct state vmap {
              #   invalid : jump forward-allow,
              #   established : accept,
              #   related : accept,
              #   new : jump forward-allow,
              #   untracked : jump forward-allow,
              # }
              jump forward-rules
            }

            chain forward-rules {
              icmpv6 type != { router-renumbering, 139 } accept comment "Accept all ICMPv6 messages except renumbering and node information queries (type 139).  See RFC 4890, section 4.3."
              ct status dnat accept comment "allow port forward"
              ${extraForwardRules}
            }
        '';
    };

    # Open ports in the firewall.
    networking.firewall = {
      enable = true;

      allowedTCPPorts = [ 22 ];
      # allowedUDPPorts = [ ... ];

      # checkReversePath = "loose";
      checkReversePath = false;

      filterForward = false;
    };
  };
}
