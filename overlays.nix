{ sources, ... }:
let
  baseConfig = {
    allowUnfree = true;
  };

  unstable = (import sources.unstable baseConfig);
in
[
  (final: prev: {
    inherit unstable;

    nix = unstable.lix;
    # nix = unstable.lix.overrideAttrs (oldAttrs: rec {
    #   patches = oldAttrs.patches or [ ]
    #     ++ [  ];
    # });
    nixfmt = unstable.nixfmt-rfc-style;
    #stable = nixpkgs-stable.legacyPackages.${prev.system};
    # devenv = devenv.packages.${prev.system}.devenv;
    # nix-inspect = nix-inspect.packages.${prev.system}.default;

    #ferm = prev.ferm.overrideAttrs (oldAttrs: rec {
    #  patches = oldAttrs.patches or [ ]
    #    ++ [ ./patches/ferm_import-ferm_wrapped.patch ];
    #});
  })
]
