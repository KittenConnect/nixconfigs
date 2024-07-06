# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  targetConfig,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.ovpn;

  forEachCFG = (
    name: val:
    builtins.listToAttrs (
      map (conf: {
        name = if name == "" then conf else lib.trivial.toFunction name conf;

        value = lib.trivial.toFunction val conf;
      }) cfg.configs
    )
  );

  openscPKCS11 = "${pkgs.opensc}/lib/opensc-pkcs11.so";
  showPKCS11 = "${pkgs.openvpn_show_pkcs11_ids}/bin/openvpn_show_pkcs11_ids.sh";
in
{
  options.services.ovpn = {
    configs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "s3nsible" ];
      description = ''
        List of OpenVPN configurations to generate.
      '';
    };

    ensureDevice = lib.mkEnableOption "YubiKey Forced Detection";

    basePath = lib.mkOption {
      type = lib.types.str;
      default = "/root/openvpn";
      example = "/etc/openvpn/configs";
      description = ''
        Folder where configurations can be found on disk.
      '';
    };

    autostart = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "s3nsible" ];
      description = ''
        List of OpenVPN configurations to start on boot.
      '';
    };
  };

  config = lib.mkIf (cfg.configs != [ ]) {
    nixpkgs.overlays = [
      (final: prev: {
        # OpenVPN w/ OpenSC pkcs11 support
        openvpn = (
          prev.openvpn.override {
            pkcs11Support = true;
            pkcs11helper = prev.pkcs11helper;
          }
        );

        openvpn_show_pkcs11_ids = (
          pkgs.writeShellScriptBin "openvpn_show_pkcs11_ids.sh" ''
            ${pkgs.openvpn}/bin/openvpn --show-pkcs11-ids ${openscPKCS11}
          ''
        );

        openvpn_systemd_launcher = (
          pkgs.writeShellScriptBin "openvpn_systemd.sh" (builtins.readFile ../scripts/openvpn_systemd.sh)
        );
      })
    ];

    environment.systemPackages = with pkgs; [
      opensc

      openvpn_show_pkcs11_ids
      openvpn_systemd_launcher
    ];

    systemd.services = (
      forEachCFG (name: "openvpn-${name}") {
        serviceConfig = {
          ExecStartPre = lib.mkIf (cfg.ensureDevice) ''${pkgs.bash}/bin/bash -c '${showPKCS11}; [[ $(''${showPKCS11} | grep DN: | wc -l) -gt 0 ]] || { echo Missing YubiKey or Certificates not found; exit 1; }' ''; # Ensure yubikey is detected
          TimeoutStartSec = 90;
        };
      }
    );

    services.openvpn.servers = forEachCFG "" (conf: {
      autoStart = builtins.elem conf cfg.autostart;

      config =
        let
          iface = builtins.substring 0 15 conf;
        in
        ''
          pkcs11-providers ${openscPKCS11}

          config ${cfg.basePath}/${conf}.ovpn
          dev ${iface}
        '';
    });
  };
}
