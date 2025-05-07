args@{ lib, ... }:
let
  sanitize = s: builtins.replaceStrings ["-"] ["_"] (lib.removeSuffix ".nix" s);
in {
  profile, # ../..,
  host, # ./.
  blacklist ? [ ],
  manual ? { },
}:
let 
  profilePeers = import (profile + /_peers) args;
  peers = lib.filterAttrs (
    n: v:
    n != "default.nix"
    && lib.hasSuffix ".nix" n
    && !lib.hasPrefix "_" n
    && !lib.hasPrefix "." n
    && !builtins.elem (lib.removeSuffix ".nix" n) blacklist
    && !builtins.elem (sanitize n) blacklist
    && !builtins.elem (host + "/${n}") (lib.attrValues manual)
  ) (builtins.readDir host);
in
(lib.filterAttrs (n: v: !builtins.elem n blacklist) profilePeers)
// (lib.mapAttrs (n: v: lib.removeAttrs (import v args) [ "_name" ]) manual)
// (lib.mapAttrs' (
  file: _:
  let
    v = import (host + "/${file}") args;
    name = v._name or sanitize file;
    value = lib.removeAttrs v [ "_name" ];
  in
  lib.nameValuePair name value
) peers)
