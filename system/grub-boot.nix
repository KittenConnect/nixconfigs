{
  pkgs,
  lib,
  targetConfig,
  ...
}:

let
  bootloader = if targetConfig ? bootloader then targetConfig.bootloader else "";
  grubBoot = (bootloader == "grub");
  serialPort = if targetConfig ? mainSerial then targetConfig.mainSerial else 0;
in
{
  config.boot.loader.grub = lib.mkIf (grubBoot) {
    memtest86.enable = true;

    ipxe = {
      netboot_xyz = ''
        #!ipxe
        dhcp
        chain --autofree http://boot.netboot.xyz
      '';
    };
    #extraEntries = ''
    #  # GRUB 2 with UEFI example, chainloading another distro
    #  menuentry "Memtest86+" {
    #    set root=($drive1)/
    #    chainloader /efi/memtest86/memtest.efi
    #  }
    #'';

    #extraFiles = {
    #  "efi/memtest86/memtest.efi" = "${pkgs.memtest86plus}/memtest.efi";
    #};
  };
}
