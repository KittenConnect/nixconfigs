# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  lib,
  kittenLib,
  pkgs,
  targetConfig,
  birdConfig,
  wgPeers,
  ...
}: let
  IFACE =
    if targetConfig ? interface
    then targetConfig.interface
    else null;

  transitedNetworks =
    if (birdConfig ? transitNetworks && birdConfig.transitNetworks != null)
    then birdConfig.transitNetworks
    else [
      "2a12:5844:1310::/44" # Transits Customer ranges: 2a12:5844:131{0-f}::/48
      kittenLib.network.internal6.cafe.kittens.loopbacks.net
      kittenLib.network.internal6.cafe.kittens.underlay.routed.net
    ];
  # wgPeers = filterAttrs (n: v: v ? wireguard && v.wireguard != { }) birdConfig.peers;

  transitIFACEs =
    [] ++ lib.optionals (birdConfig.transitInterfaces != []) birdConfig.transitInterfaces;
  kittenIFACEs = [];
  # (
  #   (attrNames wgPeers) ++ lib.optionals (birdConfig.allowedInterfaces != []) birdConfig.allowedInterfaces
  # );

  inherit
    (lib)
    mkAfter
    optionalString
    concatStringsSep
    concatMapStringsSep
    attrNames
    filterAttrs
    optional
    ;
in {
  config = {
    networking.nftables = {
      enable = true;

      tables."nixos-fw".content = let
        inherit (kittenLib.strings) quotedString;

        defines = lib.concatStringsSep "\n" [
          (
            optionalString (transitIFACEs != [])
            "define transitIFACEs = { ${concatMapStringsSep ", " quotedString transitIFACEs} }"
          )
          (optionalString (
            transitedNetworks != []
          ) "define transitNETs = { ${concatStringsSep ", " transitedNetworks} }")
          (
            optionalString (wgPeers != {})
            "define wireguardIFACEs = { ${concatMapStringsSep ", " quotedString (attrNames wgPeers)} }"
          )
          (
            optionalString (kittenIFACEs != [])
            "define kittenIFACEs = { ${concatMapStringsSep ", " quotedString kittenIFACEs} }"
          )
        ];

        extraForwardRules = lib.concatStringsSep "\n" (
          [
            ''
              ${optionalString (transitedNetworks != [] && transitIFACEs != []) ''
                # iifname $wireguardIFACEs oifname $transitIFACEs counter accept
                ip6 saddr $transitNETs  iifname $wireguardIFACEs  oifname $transitIFACEs  counter accept
                ip6 daddr $transitNETs  oifname $wireguardIFACEs  iifname $transitIFACEs  counter accept
              ''}

              ${optionalString (
                wgPeers != {}
              ) "iifname $wireguardIFACEs oifname $wireguardIFACEs counter accept"}
            ''
          ]
          ++ optional (birdConfig ? extraForwardRules) birdConfig.extraForwardRules
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

      allowedTCPPorts = [22];
      # allowedUDPPorts = [ ... ];

      # checkReversePath = "loose";
      checkReversePath = false;

      filterForward = false;
    };
  };
}
