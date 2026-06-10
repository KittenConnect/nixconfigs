{ config, lib, pkgs, ... }: {
  imports = [
    ../profile.nix
    ../../proxmox-image-profile.nix

    ./hardware-configuration.nix
    ./network-configuration.nix
  ];

  deployment.targetHost = "k8s-iguane-01";

  proxmox = {
    filenameSuffix = "361530_${config.deployment.targetHost}";

    qemuConf = {
      bios = "ovmf";
      net0 = "virtio=00:00:00:00:00:00,bridge=NAT01,firewall=0";
    };

    qemuExtraConf = {
      net1 = "virtio=00:00:00:00:00:00,bridge=vmbr69,firewall=0";
    };
  };

  kittenModules = {
    k3s.dataDisk = "/dev/disk/by-label/K3S";
  };

  services.openssh.enable = true;

  time.timeZone = "Europe/Paris";

  system.stateVersion = "25.11";
}
