{ config, pkgs, ... }:
let
in
#unstable = import <nixos-unstable> { config = baseconfig; };
{
  # kittenModules.rhabbit-consumer.enable = true;
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    htop
    tmux
    tree
    tmate
  ];
}
