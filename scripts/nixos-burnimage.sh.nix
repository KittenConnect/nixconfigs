{
  pkgs,
  lib,
  nixos-anywhere,
}: systemName: systemConfig:
pkgs.writeShellApplication {
  name = "nixos-burn";

  runtimeInputs = [systemConfig.config.nix.package nixos-anywhere];

  text = let
    inherit (lib) optionalString;
    inherit (builtins) toString toJSON;

    username = systemConfig.config.deployment.targetUser;
    userStr = optionalString hasUser "${username}@";
    hasUser = username != "" && username != null;

    hasHost = hostname != "" && hostname != null;
    hostname = systemConfig.config.deployment.targetHost;

    hasPort = port != "" && port != null;
    portStr = optionalString hasPort ":${toString port}";
    port = systemConfig.config.deployment.targetPort;

    hasOptions = options != [];
    options = systemConfig.config.deployment.sshOptions;

    destination = optionalString hasHost "${userStr}${hostname}${portStr}";

    disks = systemConfig.config.disko.devices.disk;
    devices = devices = filterAttrs (n: v: v ? device && v.device != null) disks;
  in ''
    command -v ssh
    command -v nix
    nix --version

    set -x
    [[ $# -gt 0 ]] || set -- ${
      if hasHost
      then destination
      else "--help"
    }
    REMOTE=$1
    echo "Bootstraping ${confName} via ssh on $REMOTE [ssh $@] ?"
    echo "CAUTION: Dangerous action -> will erase disks on remote"
    echo "Press [ENTER] to continue"
    read

    ssh $@ lsblk
    echo "CAUTION: Here are the disks found on the remote, is it correct ?"
    echo "Press [ENTER] again to continue"
    read

    ssh $@ xz --help

    ${concatMapStringsSep "\n" (
      x: let
        disk = disks.${x};
      in ''

        echo "Pushing ${x} -> ''${REMOTE}:${disk.device}"
        ${getBin pvPackage}/bin/pv ${images}/${x}.raw.xz | ssh $@ "xz -T0 -d -c - > ${disk.device}"
      ''
    ) (attrNames devices)}

    echo "DONE" >&2
  '';
}
# )
# (
#   lib.filterAttrs (
#     n: v: v.config.system.build ? diskoScriptNoDeps
#   ) (import ./_makeHive.nix (import ../hive.nix)).nodes
# )

