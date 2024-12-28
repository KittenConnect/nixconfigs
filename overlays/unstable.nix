let
  sources = import ../npins;

  baseConfig = import ../nixpkgs.config.nix;

  unstable = import sources.unstable baseConfig;
  nixpkgs = import sources.nixpkgs baseConfig;
in
(
  final: prev:
  {
    nixfmt = unstable.nixfmt-rfc-style;

    # sops = unstable.sops;
    # lix = unstable.lix;

    inherit unstable;
    # inherit (unstable) lix sops;
  }
)
