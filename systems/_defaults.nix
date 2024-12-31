args@{ pkgs, sources, ... }:
{
  imports = [
    ../modules/system/kitten/legacy # TODO: Remove this
    ../modules/system

    # (import "${sources.lix-module}/module.nix" { lix = sources.lix; })
    "${sources.disko}/module.nix"
    "${sources.sops-nix}/modules/sops"
  ];

  time.timeZone = "Europe/Paris";

  nixpkgs.overlays = import ../overlays args;

  # By default, Colmena will replace unknown remote profile
  # (unknown means the profile isn't in the nix store on the
  # host running Colmena) during apply (with the default goal,
  # boot, and switch).
  # If you share a hive with others, or use multiple machines,
  # and are not careful to always commit/push/pull changes
  # you can accidentaly overwrite a remote profile so in those
  # scenarios you might want to change this default to false.
  deployment.replaceUnknownProfiles = false;
}
