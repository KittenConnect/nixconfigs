{
  pkgs,
  lib,
  targetConfig,
  ...
}:

let
  bootloader = if targetConfig ? bootloader then targetConfig.bootloader else "";
  systemdBoot = (bootloader == "systemd-boot");
in
{
  config.boot.loader.systemd-boot = lib.mkIf (systemdBoot) {
    netbootxyz.enable = true;
    memtest86.enable = true;

    #extraEntries = {
    #  "memtest86.conf" = ''
    #    title Memtest86+
    #    efi /efi/memtest86/memtest.efi
    #  '';
    #};

    #extraFiles = {
    #  "efi/memtest86/memtest.efi" = "${pkgs.memtest86plus}/memtest.efi";
    #};
  };
}
