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

  ${optionalString (
    bgpMED != null && builtins.isInt bgpMED && bgpMED >= 0
  ) "define bgpMED_${toString peerName} = ${toString bgpMED};"}

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

  ${lib.concatMapStringsSep "\n" (
    x: let
      family = x.name;
      ipvX = x.value;
      X = builtins.fromJSON (builtins.substring (builtins.stringLength family - 1) 1 family);

      hasFilter = bgpFamilyFilter: bgpFamilyFilter == null || (bgpFamilyFilter != "" && bgpFamilyFilter.allowed != []);
      filterLine = direction: bgpFamilyFilter: optionalString (hasFilter bgpFamilyFilter) (indentedLines 2 (mkFilter direction "f${builtins.toString X}_${peerName}" bgpFamilyFilter));
      # _birdTable = getBirdTable X;
    in ''
      ${optionalString (ipvX != {} && ipvX.enable) ''
        ${family} ${optionalString peer.mpls "mpls"} { # MPLS = ${builtins.toString peer.mpls}
        ${filterLine "import" ipvX.bgpImports}
        ${filterLine "export" ipvX.bgpExports}
        };
      ''}
    ''
  ) (lib.attrsToList {inherit (peer) ipv4 ipv6;})}
  }
''
