{
  lib,
  config,
  sources,
  ...
}: {
  # TODO: Options + Togglable config

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Net Basics
  networking.useNetworkd = true;
  systemd.network.enable = true;
  systemd.network.wait-online.enable = lib.mkDefault false;

  # tmpFS on /tmp
  boot.tmp.useTmpfs = lib.mkDefault true;

  # Versions Dump
  environment.etc."current-system-packages".text = let
    channelUrlRev = s:
      lib.replaceStrings ["/"] ["_"] (
        lib.removePrefix "https://releases.nixos.org/" (lib.removeSuffix "/nixexprs.tar.xz" s)
      );

    sourceRevision = source:
      if source ? revision
      then "${source.version or source.branch}_${source.revision}"
      else
        (
          if source.type == "Channel"
          then channelUrlRev source.url
          else source.hash
        );

    getName = p:
      if p ? name
      then "${p.name}"
      else "${p}";
    packages = builtins.map getName config.environment.systemPackages;
    sortedUnique = l: builtins.sort builtins.lessThan (lib.unique l);

    npinSources = builtins.sort builtins.lessThan (
      lib.mapAttrsToList (n: v: "npins-sources-${n}-${sourceRevision v}") sources
    );

    formatted = builtins.concatStringsSep "\n" (
      (sortedUnique npinSources) ++ [] ++ (sortedUnique packages)
    );
  in
    formatted;
}
