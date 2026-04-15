let
  inherit
    ((import ../. {}).inputs)
    sources
    pkgs
    pkgsConfig
    ;

  unstable = import sources.unstable { config = pkgsConfig; };
in (
  final: prev: {
    nixfmt = unstable.nixfmt-rfc-style;

    # sops = unstable.sops;
    # lix = unstable.lix;

    inherit unstable;
    # inherit (unstable) lix sops;
  }
)
