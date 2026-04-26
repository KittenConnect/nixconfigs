args @ {
  lib,
  kittenLib,
  ...
}: let
  sanitize = s: builtins.replaceStrings ["-" "."] ["_" "__"] (lib.removeSuffix ".nix" s);
in
  {
    profile, # ../..,
    host, # ./.
    blacklist ? [],
    manual ? {},
  }: let
    manualFile = x: (
      if builtins.isPath x
      then x
      else host + "/${x}"
    );
    getManual = x:
      if builtins.isAttrs x
      then x
      else import (manualFile x) args;

    profilePeers = import (profile + /_peers) args;
    peerFiles =
      lib.filterAttrs
      (
        n: v:
          n
          != "default.nix"
          && lib.hasSuffix ".nix" n
          && !lib.hasPrefix "_" n
          && !lib.hasPrefix "." n
          && !builtins.elem (lib.removeSuffix ".nix" n) (map (lib.removeSuffix ".nix") blacklist)
          && !builtins.elem (sanitize n) (map sanitize blacklist)
          && !builtins.elem (host + "/${n}") (
            lib.mapAttrsToList (_: manualFile) (lib.filterAttrs (_: x: !(builtins.isAttrs x)) manual)
          )
      )
      (
        if builtins.pathExists host
        then builtins.readDir host
        else lib.warn "WARN: host peers folder [${builtins.toString host}] is inexistent" {}
      );

    peers =
      (lib.filterAttrs (n: v: !builtins.elem n blacklist) profilePeers)
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

    hasWireguard = _peer: _peer ? wireguard && _peer.wireguard != {};
    hasPeerIP = _peer: _peer ? peerIP && _peer.peerIP != null && _peer.peerIP != "";
    mkBirdPeer = _wg: _peer:
      (builtins.removeAttrs _peer ["wireguard"])
      // lib.optionalAttrs (hasWireguard _peer && !(hasPeerIP _peer)) {
        peerIP = let
          modulo = a: b: a - (a / b) * b;

          wgIP = _wg.address;
          lastByte = let
            split = lib.splitString ":" wgIP;
            len = builtins.length split;
          in
            builtins.elemAt split (len - 1);
          lastByteInt = (builtins.fromTOML "hex = 0x${lastByte}").hex;
          isFirst = (modulo lastByteInt 2) == 0;
          peerByte =
            if isFirst
            then lastByteInt + 1
            else lastByteInt - 1;

          wgPrefix = lib.removeSuffix ":${lastByte}" wgIP;
        in "${wgPrefix}:${lib.toHexString peerByte}";
      };

    mkWireguardPeer = _peer:
      (_peer.wireguard or {})
      // lib.optionalAttrs (hasWireguard _peer && builtins.isInt _peer.wireguard.address) {
        address = kittenLib.network.internal6.cafe.kittens.underlay (
          lib.toHexString _peer.wireguard.address
        );
      };
  in rec {
    global = peers;

    wireguard = lib.mapAttrs (_: mkWireguardPeer) (lib.filterAttrs (n: hasWireguard) peers);

    bird = lib.mapAttrs (n: mkBirdPeer (wireguard.${n} or {})) peers;
  }
