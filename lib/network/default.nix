args @ {lib, kittenLib, ...}: let
  inherit (kittenLib.strings) indentedLines;
  inherit (lib) concatStringsSep optionalString;

  isValidIPv4 = ip: let
    parts = lib.splitString "." ip;
    isByte = part: let
      n = builtins.parseInt part;
    in
      n >= 0 && n <= 255;
  in
    builtins.length parts == 4 && lib.all isByte parts;

  isValidIPv6 = ip: let
    parts = lib.splitString ":" ip;
    isHexPart = part: lib.stringLength part <= 4 && (part == "" || (builtins.match "[0-9a-fA-F]+" part != null));
  in
    builtins.length parts <= 8 && lib.all isHexPart parts && ip != "";

  mkFilter = direction: peerName: val: let
    direction' = direction;

    myType = kittenLib.withType {
      string = x: let
        lines = lib.splitString "\n" x;
        len = builtins.length lines;

        expanded = builtins.replaceStrings ["%{name}"] [peerName] x;
      in
        if len == 1
        then "${direction} ${expanded};"
        else ''
          ${direction} ${expanded}
        '';
      null = x: "${direction} none;";
      set = {
        peerName,
        direction ? direction',
        ranges ? [],
        allowed ? [],
        prepend ? 0,
        prependASN ? null,
        bgpMED ? null,
      }: let
        _bgpMED = if builtins.isString bgpMED
          then bgpMED
          else builtins.toString bgpMED;
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
          ${optionalString (bgpMED != null) (
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

  withCIDR = let
    splitNetwork = lib.splitString "/";
    splitPrefix = x:
      if isValidIPv4 x
      then throw "Unsupported IPv4 network ${x} passed - please implement"
      else if isValidIPv6 x
      then lib.splitString ":" x
      else throw "Invalid IPv4/IPv6 ${x} passed";
    fixedPrefix = lib.replaceStrings ["::/"] [":0/"];

    getCidr = self: let
      split = splitNetwork self.net;
      len = builtins.length split;
    in
      lib.throwIf (len != 2) "net must be of form 0000:0000:0000::/xx" (builtins.elemAt split (len - 1));

    getCleanPrefix = self: let
      split = splitNetwork self.net;
      prefix = builtins.head split;

      prefixArr = splitPrefix prefix;
      len = builtins.length prefixArr;

      cleanSplit =
        if len >= 8
        then
          lib.throwIf ((builtins.elemAt prefixArr 7) != "0")
          "IPv6 prefix ${self.net} is not valid, maybe you want to try ${fixedPrefix self.net}"
          (lib.sublist 0 (len - 1) prefixArr)
        else if
          lib.sublist (len - 2) 2 prefixArr
          == [
            ""
            ""
          ]
        then lib.sublist 0 (len - 2) prefixArr
        else prefixArr;
    in
      lib.concatStringsSep ":" cleanSplit;

    appendToPrefix = self: x: let
      prefix = getCleanPrefix self;
      split = splitPrefix prefix;
      len = builtins.length split;
      newLen = len + (builtins.length (splitPrefix x));

      longX = lib.throwIf (lib.hasInfix "::" x) "Cannot add ${x} to ${prefix} - remove :: first" x;

      val =
        if newLen == 8
        then "${prefix}:${x}"
        else if newLen < 8 && newLen > 0
        then "${prefix}::${longX}"
        else throw "cannot add ${x} to ${prefix} -> invalid IPv6 ${prefix}::${x}/${builtins.toString (getCidr self)}";
    in
      lib.throwIf (
        lib.hasPrefix ":" x || lib.hasSuffix ":" x
      ) "Cannot add ${x} to ${prefix} - remove trailing/leading : first"
      val;
  in
    args:
      if builtins.isAttrs args
      then
        {
          __toString = getCleanPrefix;
          __functor = self: x:
            if builtins.isString x
            then
              if lib.hasSuffix "/" x
              then "${appendToPrefix self (lib.removeSuffix "/" x)}/${getCidr self}"
              else appendToPrefix self x
            else if builtins.isInt x
            then
              if x == 0
              then getCleanPrefix self
              else if x < 0
              then lib.toLower "${appendToPrefix args (lib.toHexString (-1 * x))}/${getCidr args}"
              else appendToPrefix args (lib.toLower (lib.toHexString x))
            else "";

          len = lib.toInt (getCidr args);
        }
        // args
      else if builtins.isString args
      then withCIDR {net = args;}
      else throw "withCIDR needs a net argument";

  params = import ./params.nix (args // {inherit withCIDR;});
in {
  inherit mkFilter isValidIPv4 isValidIPv6;
  inherit (params) internal6;

  pretty =
    lib.filterAttrsRecursive (
      path: _:
        !(builtins.isString path && lib.hasPrefix "__" path)
        && !(builtins.isList path && lib.hasPrefix "__" (builtins.elemAt path ((builtins.length path) - 1)))
    )
    params;
}
