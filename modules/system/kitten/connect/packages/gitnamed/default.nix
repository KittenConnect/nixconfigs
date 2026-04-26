{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kittenModules.gitnamed;

  configFile =
    if isMaster
    then "master"
    else "slave";
  isMaster = cfg.masterURL == null;
in {
  options.kittenModules.gitnamed = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = false;
      description = "Kitten gitnamed NixOS package";
    };

    gitUser = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "system setup for git@ns usage";
    };

    masterURL = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      description = "the master server's URL - is master when set to null";
    };

    # TODO: keys management
  };

  config = lib.mkMerge [
    {
      nixpkgs.overlays = [
        (final: prev: {
          gitnamed-reload = pkgs.writeShellScriptBin "gitnamed-reload" ''
            if systemctl is-active bind >/dev/null; then
              exec rndc "$@"
            else
              exec sudo systemctl start bind
            fi
          '';

          gitnamed-sync = pkgs.stdenv.mkDerivation {
            pname = "gitnamed-sync";
            version = "1.0";

            src = ./syndns.py; # your existing script

            nativeBuildInputs = [pkgs.makeWrapper];

            dontUnpack = true;

            installPhase = let
              neededPackages = with pkgs; [
                python3
                bind
                openssh
                git
                sops
                ssh-to-age
              ];
            in ''
              mkdir -p $out/bin
              cp $src $out/bin/gitnamed-sync
              chmod +x $out/bin/gitnamed-sync

              wrapProgram $out/bin/gitnamed-sync \
                --prefix PATH : ${pkgs.lib.makeBinPath neededPackages}
            '';
          };
        })
      ];
    }

    (lib.mkIf (cfg.enable && isMaster && cfg.gitUser) (
      let
        git-shell = lib.getExe' pkgs.git "git-shell";
      in {
        # GIT master
        users.users.git = {
          group = "git";
          description = "GIT repositories user";
          shell = git-shell;
          isNormalUser = true;
        };
        users.groups.git = {};
        environment.shells = [git-shell];
        environment.etc."profile.local".text = ''
          if [[ "$(id -u -n)" == "git" ]]; then
            export PATH="${lib.makeBinPath (with pkgs; [git])}:''${PATH:-/run/current-system/sw/bin}"
          fi
        '';
      }
    ))

    (lib.mkIf cfg.enable {
      # Bind9 + GitNamed
      networking.nameservers = [
        "127.0.0.1"
        "::1"
      ];
      networking.firewall = {
        allowedUDPPorts = [53];
        allowedTCPPorts = [53];
      };
      services.resolved.enable = false;
      users.users.named = {
        isNormalUser = true;
        isSystemUser = lib.mkForce false;
      };
      systemd.services.bind = {
        unitConfig.ConditionFileNotEmpty = "/home/named/named.conf.${configFile}";
        serviceConfig.ProtectHome = lib.mkForce false;
        # postStart = ''
        #   cd $HOME && exec /run/current-system/sw/bin/gitnamed-sync
        # '';
      };
      services.bind = {
        enable = true;

        configFile = "/home/named/named.conf.${configFile}";

        forwarders = [
          "9.9.9.9"
          "2626:fe::fe"
        ];
      };

      sops.secrets.gitnamed_sshkey = {
        sopsFile = ../../../../../../.secrets/_gitnamed.yaml;
      };

      security.sudo.extraRules = [
        {
          commands =
            map
            (cmd: {
              command = cmd;
              options = ["NOPASSWD"];
            })
            [
              "/run/current-system/sw/bin/systemctl start bind"
              "/run/current-system/sw/bin/systemctl restart bind"
              "/run/current-system/sw/bin/systemctl stop bind"
            ];

          users = ["named"];
        }
      ];
      environment.systemPackages = lib.mkIf (cfg.enable) (
        with pkgs; [
          bind
          gitnamed-reload
          gitnamed-sync
        ]
      );

      system.activationScripts.gitnamed = let
        namedHome = config.users.users.named.home;
        rndcKey = "${namedHome}/rndc.key";
        sshKey = "${namedHome}/.ssh/id_gitnamed";
        secretKey = "/run/secrets/gitnamed_sshkey";

        runtimeDependencies = with pkgs; [
          git
          openssh
          bind
          diffutils
        ];

        masterURL =
          if isMaster
          then
            if cfg.gitUser
            then "git@127.0.0.1:gitnamed"
            else throw "TODO: implement"
          else cfg.masterURL;
      in {
        deps = ["setupSecrets"];

        text = ''
          (
            export PATH="${lib.makeBinPath runtimeDependencies}:$PATH"
            pwd

            if ! [[ -d ${namedHome}/.git ]]; then
              GIT_SSH_COMMAND="ssh -i ${secretKey} -o StrictHostKeyChecking=accept-new" git clone ${masterURL} ${namedHome}
            fi

            [[ -d ${namedHome}/.ssh ]] || mkdir -v ${namedHome}/.ssh

            if ! diff -ruN <(ssh-keygen -y -f ${sshKey}) <(ssh-keygen -y -f ${secretKey}); then
              [[ ! -f ${sshKey} ]] || mv -v ${sshKey} ${sshKey}.$$
              cp -v ${secretKey} ${sshKey}
              [[ ! -f ${sshKey}.pub ]] || mv -v ${sshKey}.pub ${sshKey}.$$.pub
              ssh-keygen -y -f ${sshKey} > ${sshKey}.pub
            fi

            [[ -f ${rndcKey} ]] || rndc-confgen -a -c ${rndcKey}

            chown -R named ${namedHome}

            ${lib.optionalString isMaster ''
            /run/wrappers/bin/sudo -u named -- /run/current-system/sw/bin/gitnamed-sync || true
          ''}
          )
        '';
      };
    })
  ];
}
