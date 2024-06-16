{ lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    krewfile
    zsh
    nixfmt-rfc-style
  ];
}
