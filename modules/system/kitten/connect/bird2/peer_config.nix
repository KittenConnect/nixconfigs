{
  lib,
  kittenLib,
  pkgs,
  peer,
  withType,
  ...
}: let
  inherit (lib) optionalString;
  inherit (kittenLib.strings) indentedLines;
  inherit (builtins) concatStringsSep toJSON;

  fromTemplateString = t: optionalString (t != null) "from ${toString t}";

  inherit
    (peer)
    enable
    peerName
    peerIP
    peerAS
    localIP
    localAS
    bgpMED
    ;

  localLine = optionalString (localIP != null) (toString localIP) + "as ${toString localAS}";
  interface = assert lib.asserts.assertMsg (peer.multihop == 0)
  "kittenModules.bird.peers.${peerName}: Multihop[${toString peer.multihop}] BGP cannot be bound to interface : ${peer.interface}";
    peer.interface;

  password = assert lib.asserts.assertMsg (
    peer.passwordRef == null
  ) "U defined a passwordRef, why do you still want to leak password ?";
    toString (
      lib.warn "bird2 peers password is insecure consider using passwordRef with a bird_secrets file" password
    );
  passwordRef =
    if peer.passwordRef != ""
    then toString peer.passwordRef
    else toString peerName;

  multihop = let
    multiHopVar =
      if peer.multihop < -1
      then -1 * peer.multihop
      else peer.multihop;
  in
    if peer.multihop == 0
    then "direct"
    else "multihop" + (optionalString (peer.multihop != -1) " ${toString multiHopVar}");

  mkFilterSection = direction: val: let
    myType = withType {
      string = x: "${direction} ${builtins.replaceStrings ["%s"] [peerName] x};";
      null = x: "${direction} none;";
      list = x:
        indentedLines 1 ''
          ${direction} filter {
            if ( net ~ [ ${concatStringsSep ", " x} ] ) then {
              accept;
            }
            reject;
          };
        '';
    };
  in
    myType val;
in ''

  ${optionalString (bgpMED != null) "define bgpMED_${toString peerName} = ${toString bgpMED};"}
  ${optionalString (peer.template == "kittunderlay") ''

    filter filter4_IN_BGP_${toString peerName} {
      if is_valid4_network() then {
        if defined( bgp_med ) then
          bgp_med = bgp_med + bgpMED_${toString peerName};
        else {
          bgp_med = bgpMED_${toString peerName};
        }
        accept;
      } else reject;
    }

    filter filter6_IN_BGP_${toString peerName} {
      if is_valid6_network() then {
        if defined( bgp_med ) then
          bgp_med = bgp_med + bgpMED_${toString peerName};
        else {
          bgp_med = bgpMED_${toString peerName};
        }
        accept;
      } else reject;
    }

  ''}

  # L: AS${toString localAS} | R: AS${toString peerAS}
  protocol bgp ${toString peerName} ${fromTemplateString peer.template} {
    ${optionalString (enable) "# "}disabled;

    local ${localLine}; # localIP: "${toString localIP}"
    neighbor ${toString peerIP} as ${toString peerAS};
    ${optionalString (peer.interface != null) ''interface "${interface}";''}
    ${multihop}; # multihop: ${toString peer.multihop}
    ${optionalString (
    peer.password != null
  ) ''password "${password}"; # Not-Secured cleartext access for @everyone''}
    ${optionalString (
    peer.passwordRef != null
  ) "password secretPassword_${passwordRef}; # Defined in secrets file"}

  ${optionalString (peer.ipv6 != {}) ''
      ipv6 {
    ${optionalString (peer.ipv6.bgpImports != "" && peer.ipv6.bgpImports != []) (
      indentedLines 2 (mkFilterSection "import" peer.ipv6.bgpImports)
    )}
    ${optionalString (peer.ipv6.bgpExports != "" && peer.ipv6.bgpExports != []) (
      indentedLines 2 (mkFilterSection "export" peer.ipv6.bgpExports)
    )}
      };
  ''}

  }
''
