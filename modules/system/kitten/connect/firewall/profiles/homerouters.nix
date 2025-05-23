args@{
  lib,
  config,
  wgpeers,
  ...
}:
let
  inherit (builtins) baseNameOf; # unsafeGetAttrPos;
  inherit (lib.strings) removeSuffix;
  # inherit (lib.attrsets) filterAttrs attrNames;

  fileName = baseNameOf (__curPos).file; # (__curPos) or (unsafeGetAttrPos "args" { inherit args; })
  profileName = lib.strings.removeSuffix ".nix" fileName;

  cfg = config.kittenModules.firewall;
  profileConf = config.kittenModules.firewall.${profileName};
in
{
  # Module Options
  options.kittenModules.firewall.${profileName} = {

  };

  # Implementation
  config = lib.mkIf (cfg.enable && cfg.profile == profileName) {
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
     kittenModules.firewall.forward.rules = '' '';
  };
}

# {
#   lib,
#   pkgs,
#   targetConfig,
#   birdConfig,
#   wgPeers,
#   ...
# }:
# let
#   IFACE = if targetConfig ? interface then targetConfig.interface else null;

#   transitedNetworks =
#     if (birdConfig ? transitNetworks && birdConfig.transitNetworks != null) then
#       birdConfig.transitNetworks
#     else
#       [
#         "2a13:79c0:ff00::/44" # Transits Customer ranges: 2a13:79c0:{ff00-ff0f}::/48
#         "2a13:79c0:ffff:fefe::/64"
#         "2a13:79c0:ffff:feff:b00b::/80"
#       ];
#   # wgPeers = filterAttrs (n: v: v ? wireguard && v.wireguard != { }) birdConfig.peers;

#   transitIFACEs =
#     [ ]
#     ++ lib.optionals (birdConfig.transitInterfaces != [ ]) birdConfig.transitInterfaces;

#   kittenIFACEs = [ ];
#   # (
#   #   (attrNames wgPeers) ++ lib.optionals (birdConfig.allowedInterfaces != []) birdConfig.allowedInterfaces
#   # );

#   inherit (lib)
#     mkAfter
#     optionalString
#     concatStringsSep
#     concatMapStringsSep
#     attrNames
#     filterAttrs
#     optional
#     ;
# in
# {

#   config = {
#     # environment.systemPackages = with pkgs; [ ferm ]; # Prepare an eventual switch to FERM

#     networking.nftables = {
#       enable = true;

#       tables."nixos-fw".content =
#         let
#           quoteString = x: ''"${x}"'';

#           defines = lib.concatStringsSep "\n" ([
#             (optionalString (transitIFACEs != [ ])
#               "define transitIFACEs = { ${concatMapStringsSep ", " quoteString transitIFACEs} }"
#             )
#             (optionalString (
#               transitedNetworks != [ ]
#             ) "define transitNETs = { ${concatStringsSep ", " transitedNetworks} }")
#             (optionalString (wgPeers != { })
#               "define wireguardIFACEs = { ${concatMapStringsSep ", " quoteString (attrNames wgPeers)} }"
#             )
#             (optionalString (kittenIFACEs != [ ])
#               "define kittenIFACEs = { ${concatMapStringsSep ", " quoteString kittenIFACEs} }"
#             )
#           ]);

#           extraForwardRules = lib.concatStringsSep "\n" (
#             [
#               ''
#                 ${optionalString (transitedNetworks != [ ] && transitIFACEs != [ ]) ''
#                   # iifname $wireguardIFACEs oifname $transitIFACEs counter accept
#                   ip6 saddr $transitNETs  iifname $wireguardIFACEs  oifname $transitIFACEs  counter accept
#                   ip6 daddr $transitNETs  oifname $wireguardIFACEs  iifname $transitIFACEs  counter accept
#                 ''}

#                 ${optionalString (
#                   wgPeers != { }
#                 ) "iifname $wireguardIFACEs oifname $wireguardIFACEs counter accept"}

#                 # ip6 daddr 2a13:79c0:ff00::/48 counter accept
#                 # ip6 daddr { 2a13:79c0:ffff:feff:b00b:3945:a51:b00b, 2a13:79c0:ffff:feff:b00b:3945:a51:dead } counter accept

#                 # ip6 daddr 2a13:79c0:ffff:fefe::113:91 tcp dport { 179, 1790 } counter accept

#                 # ip6 saddr 2a13:79c0:ffff:feff:b00b::/80 ip6 daddr 2a13:79c0:ffff:fefe::/64 counter accept

#                 # ip6 saddr { 2a13:79c0:ffff:fefe::/64, 2a13:79c0:ffff:feff::/64 } ip6 daddr { 2a13:79c0:ffff:fefe::/64, 2a13:79c0:ffff:feff::/64 } counter accept
#               ''
#             ]

#             ++ optional (birdConfig ? extraForwardRules) birdConfig.extraForwardRules
#           );
#         in
#         mkAfter ''
#           # FireWall Test Configs
#           ${defines}

#             chain forward {
#               type filter hook forward priority filter; policy drop;
#               # We want StateLess firewalling
#               # ct state vmap {
#               #   invalid : jump forward-allow,
#               #   established : accept,
#               #   related : accept,
#               #   new : jump forward-allow,
#               #   untracked : jump forward-allow,
#               # }
#               jump forward-rules
#             }

#             chain forward-rules {
#               icmpv6 type != { router-renumbering, 139 } accept comment "Accept all ICMPv6 messages except renumbering and node information queries (type 139).  See RFC 4890, section 4.3."
#               ct status dnat accept comment "allow port forward"
#               ${extraForwardRules}
#             }
#         '';
#     };

#     # Open ports in the firewall.
#     networking.firewall = {
#       enable = true;

#       allowedTCPPorts = [ 22 ];
#       # allowedUDPPorts = [ ... ];

#       # checkReversePath = "loose";
#       checkReversePath = false;

#       filterForward = false;
#     };
#   };
# }
