{
  lib,
  kittenLib,
  pkgs,
  ...
}: peer: let
  inherit (lib) optionalString;
  inherit (kittenLib.strings) indentedLines;
  inherit (kittenLib.network) mkFilter;
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

  peerMED = bgpMED;

  _localIP = optionalString (localIP != null) (toString localIP);

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
in ''

  ${optionalString (bgpMED != null && builtins.isInt bgpMED && bgpMED >= 0) "define bgpMED_${toString peerName} = ${toString bgpMED};"}

  # L: AS${toString localAS} | R: AS${toString peerAS}
  protocol bgp ${toString peerName} ${fromTemplateString peer.template} {
    ${optionalString enable "# "}disabled;

    local ${_localIP} as ${toString localAS}; # localIP: "${toString localIP}"
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
    ${optionalString (peer.ipv6.bgpImports == null || (peer.ipv6.bgpImports != "" && peer.ipv6.bgpImports.allowed != [])) (
      indentedLines 2 (mkFilter "import" peerName peer.ipv6.bgpImports)
    )}
    ${optionalString (peer.ipv6.bgpExports == null || (peer.ipv6.bgpExports != "" && peer.ipv6.bgpExports.allowed != [])) (
      indentedLines 2 (mkFilter "export" peerName peer.ipv6.bgpExports)
    )}
      };
  ''}

  }
''
