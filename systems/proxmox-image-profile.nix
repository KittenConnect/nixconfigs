{modulesPath, lib, config, ...}: {
  imports = [(modulesPath + "/virtualisation/proxmox-image.nix")];

  config = {
    virtualisation.vmVariant = {
      virtualisation.graphics = false;

      services.getty.autologinUser = "root";
      boot.consoleLogLevel = 7;
      boot.kernelParams = [
        "systemd.journald.forward_to_console=1"
        "systemd.log_level=info"
      ];
    };

    kittenModules.nixConfig.nixosFolder = null;

    # Bootloader.
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.enable = true;


    proxmox = {
      cloudInit.enable = false; # me no need - breaks with hive networking.hostName option definition

      qemuConf = {
        bios = "ovmf";
        net0 = lib.mkDefault "virtio=00:00:00:00:00:00,bridge=vmbr0,firewall=0";
      };
    };


    # system.build.deployImageScript = config.system.build.googleDeployImage;
  };
}
