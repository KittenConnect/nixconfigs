{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  # nativeBuildInputs is usually what you want -- tools you need to run
  shellHook = ''
    alias nixos-anywhere='nix run -f ${./.}/_scripts/nixos-anywhere.nix'
  '';


  nativeBuildInputs = with pkgs; [
    colmena
    npins
  ];
}
