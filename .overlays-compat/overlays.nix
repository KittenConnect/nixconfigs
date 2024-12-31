final: prev:
with prev.lib;
let
  # Load the system config and get the `nixpkgs.overlays` option
  overlays = (import ../ci/_configuration.nix).config.nixpkgs.overlays; #(import <nixpkgs/nixos> { }).config.nixpkgs.overlays;
in
  # Apply all overlays to the input of the current "main" overlay
  foldl' (flip extends) (_: prev) overlays final
