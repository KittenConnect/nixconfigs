{pkgs, lib, config, ...}: {
  systemd.services.systemd-resolved = lib.mkForce {
    description = "Fake systemd-resolved";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/true";
      RemainAfterExit = true;
    };
    wantedBy = [ ];
  };
  # Networking
  services.cloud-init = {
    enable = lib.mkForce false;
    ext4.enable = true;
    network.enable = true;
    settings = {
      datasource_list = ["Vultr"];
      disable_root = false;
      ssh_pwauth = 0;
      manage_resolv_conf = true;
      resolv_conf = { inherit (config.networking) nameservers;};

      updates = {
        network = {
          when = [
            "boot"
            "boot-legacy"
            "boot-new-instance"
            "hotplug"
          ];
        };
      };
    };
  };

}