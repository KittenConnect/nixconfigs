{ pkgs, ... }:
{
  # This module will be imported by all hosts
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    nyancat
    fastfetch
    nixfmt
  ];
}
