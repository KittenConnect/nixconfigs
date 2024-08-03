{
  pkgs,
  lib,
  config,
  ...
}:
{

  nix = {
    #package = pkgs.nixFlakes;
    settings = {
      auto-optimise-store = true;
    };
    gc = {
      automatic = false; # TODO: Implement static N generations
      dates = "daily";
      options =
        let
          default = 10; # TODO: Find a better way to do it

          generations = builtins.toString (
            if config.boot.loader.systemd-boot.enable then
              config.boot.loader.systemd-boot.configurationLimit
            else if config.boot.loader.grub.enable then
              config.boot.loader.grub.configurationLimit
            else if config.boot.loader.generic-extlinux-compatible.enable then
              config.boot.loader.generic-extlinux-compatible.configurationLimit
            else
              default
          );
        in
        "--delete-older-than +${generations}"; # Not supported
    };
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    # Without any `nix.nixPath` entry:
    #nixPath =
    #  # Prepend default nixPath values.
    #  options.nix.nixPath.default
    #  ++
    #  # Append our nixpkgs-overlays.
    #  [ "nixpkgs-overlays=/etc/nixos/overlays-compat/" ];
  };
}
