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
  config.boot.kernelParams = [
    "console=tty1"
    "console=ttyS${toString serialPort},115200"
  ] ++ lib.optionals (serialPort != 0) [ "console=ttyS0,115200" ];

  config.boot.loader.grub = lib.mkIf (grubBoot) {
    extraConfig = ''
      serial --unit=${toString serialPort} --speed=115200 --word=8 --parity=no --stop=1
      terminal_input --append serial
      terminal_output --append serial
    '';
  };
}
