{ config, pkgs, ... }:
let
in
#unstable = import <nixos-unstable> { config = baseconfig; };
{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    vscode
    git
    htop
    #  wget
    unstable.nix-output-monitor
    nixfmt
    ripgrep
    tree
    colmena
    npins
  ];
}
