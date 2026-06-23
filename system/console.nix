{
  pkgs,
  lib,
  config,
  targetConfig,
  ...
}:
let
  nerdFonts = true;

  palette = [
    "000000"
    "CC0000"
    "4E9A06"
    "C4A000"
    "3465A4"
    "75507B"
    "06989A"
    "D3D7CF"
    "555753"
    "EF2929"
    "8AE234"
    "FCE94F"
    "739FCF"
    "AD7FA8"
    "34E2E2"
    "EEEEEC"
  ];

  inherit (lib) mkDefault;
in
{
  services.gpm.enable = mkDefault true;

  # systemd.units."kmsconvt@.service".ExecStart = lib.mkIf (nerdFonts) (
  #   let
  #     autologinArg = lib.optionalString (
  #       config.services.kmscon.autologinUser != null
  #     ) "-a ${config.services.kmscon.autologinUser}";

  #     extraOptions = config.services.kmscon.extraOptions;
  #   in
  #   ''${pkgs.kmscon}/bin/kmscon "--vt=%I" ${extraOptions} --seats=seat0 --no-switchvt --configdir ${configDir} --login -- ${pkgs.util-linux}/bin/agetty  -o '-p ${autologinArg} -- \\u' - xterm-256color''
  # );

  # conf.options.services.openssh.settings.value.Macs

  services.kmscon = lib.mkIf (nerdFonts) {
    enable = true;
    hwRender = false;

    fonts = [
      {
        name = "Hack Nerd Font Mono";
        package = with pkgs; (nerdfonts.override { fonts = [ "Hack" ]; });
      }
    ];

    extraConfig = ''
      font-size=16
    '';
  };

  # config.systemd.units."kmsconvt@.service".unit.text

  # conf.options.services.openssh.settings.value.Macs

  console = {
    earlySetup = true;

    font = with pkgs; "${powerline-fonts}/share/consolefonts/ter-powerline-v16b.psf.gz";

    colors = palette;
  };
}
