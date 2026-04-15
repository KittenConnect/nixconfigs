let
  # sources = import ../npins;
  inherit
    (builtins)
    readDir
    filter
    attrNames
    map
    ;
  # inherit (lib.strings) hasPrefix hasSuffix;

  inherit
    ((import ../. {}).inputs)
    sources
    pkgs
    pkgsConfig
    kittenLib
    ;
  unstable = import sources.unstable {config = pkgsConfig;};

  # ugly implementations to avoid using pkgs/lib
  hasPrefix = q: s: let
    split = builtins.split q s;
    len = builtins.length split;
  in
    if len == 1
    then false
    else builtins.head split == "" && (builtins.elemAt split 1) == [];

  hasSuffix = q: s: let
    split = builtins.split q s;
    len = builtins.length split;
  in
    if len == 1
    then false
    else (builtins.elemAt split (len - 1)) == "" && (builtins.elemAt split (len - 2)) == [];

  overlaysPath = ./.;
  files = let
    dirFiles = readDir overlaysPath;
    isFile = x: dirFiles.${x} == "regular";
  in
    filter isFile (attrNames dirFiles);

  filterFunc = file: file != "default.nix" && hasSuffix ".nix" file && !hasPrefix "_" file;
  overlays = map (file: import (overlaysPath + "/${file}")) (filter filterFunc files);
in
  overlays
  ++ [
    (final: prev: {
      nixfmt = unstable.nixfmt-rfc-style;

      # sops = unstable.sops;
      # lix = unstable.lix;
      lib =
        (prev.lib or {})
        // {
          kitten = kittenLib;
        };

      inherit unstable;
      # inherit (unstable) lix sops;
    })
  ]
# {
#   inherit overlaysPath overlays baseConfig sources;
# }

