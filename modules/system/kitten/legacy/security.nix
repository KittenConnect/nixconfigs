{
  lib,
  pkgs,
  config,
  ...
}:

let
  noPasswdCommands = [
    "/run/current-system/sw/bin/reboot"
    "/run/current-system/sw/bin/poweroff"

    "/run/current-system/sw/bin/systemctl suspend"

    "/run/current-system/sw/bin/systemd-tty-ask-password-agent --query"

    "/run/current-system/sw/bin/nix profile wipe-history --profile /nix/var/nix/profiles/system"
    "/run/current-system/sw/bin/nixos-rebuild *"
  ];

  noPasswdServices = [ ];
in
{
  users.users.root = {
    initialPassword = lib.mkDefault "toor";

    openssh.authorizedKeys.keys = lib.mkDefault [
      # change this to your ssh key
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPxJpIrlaMMuw+zqOlZa35ehViBytyROvdf73poXTlVz"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINC+U2GVzJm2vPdmeSwiImGuZ82prwMybkjmrfLdOsWu"
    ];
  };

  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };

  security = {
    sudo = {
      enable = true;
      extraRules =
        [
          {
            commands = map (cmd: {
              command = cmd;
              options = [ "NOPASSWD" ];
            }) (noPasswdCommands);

            groups = [ "wheel" ];
          }
        ]
        ++ map (svc: {
          commands =
            map
              (cmd: {
                command = cmd;
                options = [ "NOPASSWD" ];
              })

              [
                "/run/current-system/sw/bin/systemctl start ${svc}"
                "/run/current-system/sw/bin/systemctl restart ${svc}"
                "/run/current-system/sw/bin/systemctl stop ${svc}"
              ];

          groups = [ "wheel" ];
        }) noPasswdServices;

      # ++ lib.flatten (
      #   map (svc: [
      #     "/run/current-system/sw/bin/systemctl start ${svc}"
      #     "/run/current-system/sw/bin/systemctl restart ${svc}"
      #     "/run/current-system/sw/bin/systemctl stop ${svc}"
      #   ]) noPasswdServices
      # )
      # extraConfig = with pkgs; ''
      #   Defaults:picloud secure_path="${lib.makeBinPath [
      #     systemd
      #   ]}:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
      # '';
    };

    # pam.services.sudo = {
    #   rules.auth.rssh = {
    #     order = config.rules.auth.unix.order - 10;
    #     control = "sufficient";
    #     modulePath = "${pkgs.pam_rssh}/lib/libpam_rssh.so";
    #     #settings = {
    #     #  authorized_keys_command = "/etc/ssh/authorized_keys_command";
    #     #  authorized_keys_command_user = "nobody";
    #     #};
    #   };
    # };

    sudo.extraConfig = ''
      Defaults env_keep+=SSH_AUTH_SOCK
    '';
  };
}
