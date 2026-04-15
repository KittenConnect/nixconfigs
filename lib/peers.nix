args @ {lib, ...}: let
  sanitize = s: builtins.replaceStrings ["-" "."] ["_" "__"] (lib.removeSuffix ".nix" s);
in
  {
    profile, # ../..,
    host, # ./.
    blacklist ? [],
    manual ? {},
    # Use new easier output
    nextGen ? false,
  }: let
    manualFile = x: (if builtins.isPath x then x else host + "/${x}");
    getManual = x: if builtins.isAttrs x then x else import (manualFile x) args;

    profilePeers = import (profile + /_peers) args;
    peerFiles = lib.filterAttrs (
      n: v:
        n
        != "default.nix"
        && lib.hasSuffix ".nix" n
        && !lib.hasPrefix "_" n
        && !lib.hasPrefix "." n
        && !builtins.elem (lib.removeSuffix ".nix" n) (map (lib.removeSuffix ".nix") blacklist)
        && !builtins.elem (sanitize n) (map sanitize blacklist)
        && !builtins.elem (host + "/${n}") (lib.mapAttrsToList (_: manualFile) (lib.filterAttrs (_: x: !(builtins.isAttrs x)) manual))
    ) (builtins.readDir host);

    peers = (lib.filterAttrs (n: v: !builtins.elem n blacklist) profilePeers)
    // (lib.mapAttrs (n: v: lib.removeAttrs (getManual v) ["_name"]) manual)
    // (lib.mapAttrs' (
        file: _: let
          v = import (host + "/${file}") args;
          name = v._name or sanitize file;
          value = lib.removeAttrs v ["_name"];
        in
          lib.nameValuePair name value
      )
      peerFiles);
  in if nextGen then {
   inherit peers;

  wireguard = (
    lib.mapAttrs (n: v: v.wireguard) (lib.filterAttrs (n: v: v ? wireguard && v.wireguard != { }) peers)
  );

  bird = lib.mapAttrs (n: v: builtins.removeAttrs v [ "wireguard" ]) peers;
  } else peers
