#! /usr/bin/env nix-shell
#! nix shell -f 
{
  pkgs ? import (import ./npins).nixpkgs { },
}:
pkgs.mkShell {
  # nativeBuildInputs is usually what you want -- tools you need to run
  shellHook = ''
    alias nixos-anywhere='nix run -f ${./.}/_scripts/nixos-anywhere.nix'
  '';


  nativeBuildInputs = with pkgs; [
    colmena
    act
    # nixel
    nixfmt-rfc-style
    npins
  ];
}
