{
  lib,
  kittenLib,
  pkgs,
  peer,
  ...
}:
let
  inherit (lib) optionalString;
  inherit (kittenLib.strings) indentedLines;
  inherit (kittenLib) withType;
  inherit (builtins) concatStringsSep toJSON;

  fromTemplateString = t: optionalString (t != null) "from ${toString t}";

  inherit (peer)
    enable
    peerName
    peerIP
    peerAS
    localIP
    localAS
    bgpMED
    ;

  _localIP = optionalString (localIP != null) (toString localIP);

  interface =
    assert lib.asserts.assertMsg (peer.multihop == 0)
      "kittenModules.bird.peers.${peerName}: Multihop[${toString peer.multihop}] BGP cannot be bound to interface : ${peer.interface}";
    peer.interface;

  password =
    assert lib.asserts.assertMsg (
      peer.passwordRef == null
    ) "U defined a passwordRef, why do you still want to leak password ?";
    toString (
      lib.warn "bird2 peers password is insecure consider using passwordRef with a bird_secrets file" password
    );
  passwordRef = if peer.passwordRef != "" then toString peer.passwordRef else toString peerName;

  multihop =
    let
      multiHopVar = if peer.multihop < -1 then -1 * peer.multihop else peer.multihop;
    in
    if peer.multihop == 0 then
      "direct"
    else
      "multihop" + (optionalString (peer.multihop != -1) " ${toString multiHopVar}");

  mkFilterSection =
    direction: val:
    let
      direction' = direction;

      myType = withType {
        string =
          x:
          let
            lines = lib.splitString "\n" x;
            len = builtins.length lines;

            expanded = builtins.replaceStrings [ "%{name}" ] [ peerName ] x;
          in
          if len == 1 then
            "${direction} ${expanded};"
          else
            ''
              ${direction} ${expanded}
            '';
        null = x: "${direction} none;";
        set =
          {
            peerName,
            direction ? direction',
            ranges ? [ ],
            allowed ? [],
            prepend ? 0,
            prependASN ? null,
            bgpMED ? null,
          }: let
          _bgpMED = if builtins.isString bgpMED then bgpMED else if builtins.isInt bgpMED then "bgpMED_${toString peerName}" else builtins.toString bgpMED;
          in
          indentedLines 1 ''
            ${direction} filter {
              if ( ${concatStringsSep " || " allowed} ) then {
            ${optionalString (prepend > 0) (
              indentedLines 2 ''
                if bgp_path ~ [= ${builtins.toString prependASN} =] then {
                  # Reduce priority artificially by prepending [x${builtins.toString prepend}]
                  ${concatStringsSep " " (
                    builtins.genList (x: "bgp_path.prepend(${builtins.toString prependASN});") prepend
                  )}
                }
              ''
            )}
            ${optionalString (bgpMED != null && bgpMED > (-1)) (
              indentedLines 2 ''
                if defined( bgp_med ) then
                  bgp_med = bgp_med + ${_bgpMED};
                else {
                  bgp_med = ${_bgpMED};
                }
              ''
            )}
                accept;
              }
              reject;
            };
          '';
      };
    in
    myType val;
in
''

  ${optionalString (bgpMED != null && builtins.isInt bgpMED) "define bgpMED_${toString peerName} = ${toString bgpMED};"}

  # L: AS${toString localAS} | R: AS${toString peerAS}
  protocol bgp ${toString peerName} ${fromTemplateString peer.template} {
    ${optionalString (enable) "# "}disabled;

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

  ${optionalString (peer.ipv6 != { }) ''
      ipv6 {
    ${optionalString (peer.ipv6.bgpImports != null && peer.ipv6.bgpImports != "" && peer.ipv6.bgpImports.allowed != [ ]) (
      indentedLines 2 (mkFilterSection "import" peer.ipv6.bgpImports)
    )}
    ${optionalString (peer.ipv6.bgpExports != null && peer.ipv6.bgpExports != "" && peer.ipv6.bgpExports.allowed != [ ]) (
      indentedLines 2 (mkFilterSection "export" peer.ipv6.bgpExports)
    )}
      };
  ''}

  }
''
