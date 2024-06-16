# https://nixos.wiki/wiki/Flakes
{
  description = "System configurations";

  inputs = {

    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-24.05";
    };

    # darwin = {
    #   url = "github:lnl7/nix-darwin";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };

    nixpkgs-master = {
      url = "github:NixOS/nixpkgs/master";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-config = {
      url = "gitlab:toinux/homefiles";
      # url = "git+file:///home/toinux/Documents/homefiles";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    krewfile = {
      url = "github:brumhard/krewfile";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-inspect = {
      url = "github:bluskript/nix-inspect";
    };

    # devenv = {
    #   url = "github:cachix/devenv/latest";
    #   inputs.nixpkgs.follows = "nixpkgs";
    #   inputs.nix.follows = "nix";
    # };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixpkgs-master,
      nixos-hardware,
      nix-inspect,
      disko,
      sops-nix,
      home-manager,
      home-config,
      krewfile,
      ...
    # devenv,
    # darwin,
    }@args:
    let
      inherit (builtins) pathExists toJSON;

      inherit (nixpkgs.lib)
        foldl'
        mapAttrs
        attrNames
        filterAttrs
        assertMsg
        genAttrs
        getBin
        concatMapStringsSep
        optionals

        nixosSystem
        ;

      # TODO: Use flake-utils to do this well
      mkLinuxSystem =
        {
          target,
          targetConfig,
          profile ? targetConfig.profile,
          system ? "x86_64-linux",
          kubeConfig ? { },
        }:
        nixosSystem (
          # let
          #   inherit (nixpkgs.legacyPackages.${system}) writeShellScriptBin;
          # in
          {
            inherit system;

            modules = [

              (if targetConfig ? config then { config = targetConfig.config; } else { })

              # Pass options + Args
              {
                _module.args = {
                  targetConfig = targetConfig;
                  targetProfile = profile;
                  target = target;
                  bootdisk = targetConfig.bootdisk;
                  kubeConfig = kubeConfig;
                };
              }

              # Home + Users config
              (
                {
                  config,
                  lib,
                  pkgs,
                  ...
                }:

                let
                  userName = "toinux";
                  homeDir = "/home/${userName}";
                in
                {
                  config = {
                    networking.hostName = "${target}";

                    users.users.${userName} = {
                      isNormalUser = true;
                      home = homeDir;
                      # description = "Antoine '${userName}'";
                      shell = pkgs.zsh;
                      extraGroups =
                        [ "wheel" ]
                        ++ optionals (config.services.xserver.enable) [ "input" ]
                        ++ optionals (config.networking.networkmanager.enable) [ "networkmanager" ]
                        ++ optionals (config.virtualisation.docker.enable) [ "docker" ]
                        ++ optionals (config.virtualisation.libvirtd.enable) [ "libvirtd" ];

                      initialPassword = "totofaitsestests";
                    };

                    home-manager.users.${userName} = home-config.lib.mkHomeConfiguration userName homeDir [
                      ./_home/configuration.nix
                    ];

                    users.users.root.shell = pkgs.zsh;
                    home-manager.users.root = home-config.lib.mkHomeConfiguration "root" "/root" [
                      ./_home/configuration.nix
                    ];
                  };
                }
              )

              ./_system/configuration.nix # Global System config

              (./hosts + "/${profile}/configuration.nix")

              # Disk Partitioning
              disko.nixosModules.disko
              (
                if targetConfig ? diskTemplate && targetConfig.diskTemplate != null then
                  ./_diskos + "/${targetConfig.diskTemplate}.nix"
                else
                  let
                    diskoCfg = (./hosts + "/${profile}/${target}/disk-config.nix");
                  in
                  assert assertMsg (pathExists diskoCfg)
                    "${target}: diskTemplate undefined and ${diskoCfg} inexistant, dunno what to do";
                  diskoCfg
              )

              # Host-Specific config
              (./hosts + "/${profile}/${target}/configuration.nix") # HostSpecific configuration
              (./hosts + "/${profile}/${target}/hardware-configuration.nix") # Hardware Detection

              # Home-Manager + options
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                # Optionally, use home-manager.extraSpecialArgs to pass arguments to home.nix
              }

              # Use Mozilla SOPS as secrets manager
              sops-nix.nixosModules.sops
              { sops.defaultSopsFile = ./secrets/${target}.yaml; }

              # Overlays
              (
                { ... }:
                {
                  nixpkgs.overlays = [
                    # https://github.com/NixOS/nixpkgs/issues/97855#issuecomment-1075818028
                    #(self: super: {
                    #  my-nixos-option =
                    #    let
                    #      flake-compact = super.fetchFromGitHub {
                    #        owner = "edolstra";
                    #        repo = "flake-compat";
                    #        rev = "12c64ca55c1014cdc1b16ed5a804aa8576601ff2";
                    #        sha256 = "sha256-hY8g6H2KFL8ownSiFeMOjwPC8P0ueXpCVEbxgda3pko=";
                    #      };
                    #      prefix = ''(import ${flake-compact} { src = ~/src/vidbina/nixos-configuration; }).defaultNix.nixosConfigurations.${target}'';
                    #    in
                    #    super.runCommand "nixos-option" { buildInputs = [ super.makeWrapper ]; } ''
                    #      makeWrapper ${super.nixos-option}/bin/nixos-option $out/bin/nixos-option \
                    #        --add-flags --config_expr \
                    #        --add-flags "\"${prefix}.config\"" \
                    #        --add-flags --options_expr \
                    #        --add-flags "\"${prefix}.options\""
                    #    '';
                    #})
                    krewfile.overlay

                    (final: prev: {
                      master = nixpkgs-master.legacyPackages.${prev.system};
                      unstable = nixpkgs-unstable.legacyPackages.${prev.system};
                      # devenv = devenv.packages.${prev.system}.devenv;
                      # nix-inspect = nix-inspect.packages.${prev.system}.default;

                      # ferm = prev.ferm.overrideAttrs (oldAttrs: rec {
                      #   patches = oldAttrs.patches or [ ] ++ [ ./patches/ferm_import-ferm_wrapped.patch ];
                      # });
                    })
                  ];
                }
              )
              (
                let
                  disableModules = [ ];

                  localModules = [ "nixos/modules/services/ttys/kmscon.nix" ];

                  masterModules = [
                    # "nixos/modules/programs/kubeswitch.nix"
                  ];

                  unstableModules = [ ];
                  # stableModules = [ ];

                  getModule = input: (x: "${input}/${x}");
                in
                {
                  disabledModules = map (getModule args.nixpkgs) (
                    disableModules ++ localModules ++ masterModules ++ unstableModules
                    # ++ stableModules
                  );

                  imports =
                    (map (getModule ./modules) localModules)
                    ++ (map (getModule args.nixpkgs-master) masterModules)
                    ++ (map (getModule args.nixpkgs-unstable) unstableModules)
                  # ++ (map (getModule args.nixpkgs-stable) stableModules)
                  ;
                }
              )
            ];
          });

      targetConfigs =
        let
          hosts = import ./hosts (args // { lib = args.nixpkgs.lib; });
        in
        foldl' (
          acc: profile:
          let
            configs = hosts.${profile};
          in
          (mapAttrs (name: value: { inherit profile; } // value) configs) // acc
        ) (import ./targets.nix { }) (attrNames hosts);

      # TODO: Move this
      masterNodes = [ "stonkstation" ];
      controllers = [ "stonkstation" ];
    in
    {

      #   homeConfigurations = {
      #      "toinux" = home-config.lib.mkHomeConfiguration userName homeDir [ ./_home/configuration.nix ];
      #   };

      nixosConfigurations = (
        genAttrs (attrNames targetConfigs) (
          target:
          mkLinuxSystem {
            inherit target;

            # TODO: moveThis
            kubeConfig = {
              master = builtins.elem "${target}" masterNodes;
              controller = builtins.elem "${target}" controllers;
            };

            # This good
            targetConfig = targetConfigs.${target};
          }
        )
      );

      packages =
        let
          systems = [ "x86_64-linux" ];
        in
        genAttrs systems (
          system:
          let
            inherit (nixpkgs.legacyPackages.${system}) writeShellScriptBin;
          in
          {
            bootstrap = genAttrs (attrNames self.outputs.nixosConfigurations) (
              confName:
              writeShellScriptBin "bootstrap-${confName}.sh" (
                let
                  package = nixpkgs.legacyPackages.${system}.nix;
                in
                ''
                  set -x
                  [[ $# -gt 0 ]] || set -- --help

                  ${getBin package}/bin/nix --extra-experimental-features 'nix-command flakes' run github:nix-community/nixos-anywhere -- --option show-trace true --flake ${self.outPath}#${confName} $@
                ''
              )
            );

            rebuild = genAttrs (attrNames self.outputs.nixosConfigurations) (
              confName:
              writeShellScriptBin "rebuild-${confName}.sh" (
                let
                  package = nixpkgs.legacyPackages.${system}.nixos-rebuild;
                  nomPackage = nixpkgs.legacyPackages.${system}.nix-output-monitor;
                in
                ''
                  set -x
                  [[ $# -gt 0 ]] || set -- --help

                  ${getBin package}/bin/nixos-rebuild -L --show-trace --option extra-experimental-features 'nix-command flakes' --option eval-cache false --flake ${self.outPath}#${confName} $@ |& ${getBin nomPackage}/bin/nom
                ''
              )
            );

            images = genAttrs (attrNames self.outputs.nixosConfigurations) (
              confName:
              let
                nixConf = self.outputs.nixosConfigurations.${confName};
              in
              nixConf.config.system.build.diskoImages
            );

            compressedImages = genAttrs (attrNames self.outputs.nixosConfigurations) (
              confName:
              let
                pkgs = nixpkgs.legacyPackages.${system};
                nixConf = self.outputs.nixosConfigurations.${confName};
                diskoImages = nixConf.config.system.build.diskoImages;
              in
              pkgs.runCommand "compressed-disko-${confName}" { nativeBuildInput = [ diskoImages ]; } ''
                pwd

                tree="${pkgs.tree}/bin/tree"
                xz="${pkgs.xz}/bin/xz"

                $tree $nativeBuildInput .

                mkdir -pv $out
                cd $nativeBuildInput

                echo Compressing disk images with xz
                echo CAUTION: May take some times

                find . -name '*.raw' -print -exec bash -c "$xz -T0 --stdout '{}' > '$out/{}.xz'" \;
              ''

            );

            ddbootstrap = genAttrs (attrNames self.outputs.nixosConfigurations) (
              confName:
              writeShellScriptBin "bootstrapImageWithDD-${confName}.sh" (
                let
                  pvPackage = nixpkgs.legacyPackages.${system}.pv;

                  disks = self.outputs.nixosConfigurations.${confName}.config.disko.devices.disk;
                  images = self.outputs.packages.${system}.images.${confName};

                  devices = filterAttrs (n: v: v ? device && v.device != null) disks;
                in
                ''
                  set -eu -o pipefail
                  set -x

                  REMOTE=$1
                  echo "Bootstraping ${confName} via ssh on $REMOTE [ssh $@] ?"
                  echo "CAUTION: Dangerous action -> will erase disks on remote"
                  echo "Press [ENTER] to continue"
                  read

                  ssh $@ lsblk
                  echo "CAUTION: Here are the disks found on the remote, is it correct ?"
                  echo "Press [ENTER] again to continue"
                  read

                  ssh $@ xz --help


                  ${concatMapStringsSep "\n" (
                    x:
                    let
                      disk = disks.${x};
                    in
                    ''
                      echo "Pushing ${x} -> ''${REMOTE}:${disk.device}"
                      ${getBin pvPackage}/bin/pv ${images}/${x}.raw.xz | ssh $@ "xz -T0 -d -c - > ${disk.device}"
                    ''
                  ) (attrNames devices)}
                ''
              )
            );
          }
        );

      # darwinConfigurations = (nixpkgs.lib.genAttrs targets
      #   (target: mkLinuxSystem {
      #     inherit target;

      #     targetConfig = targetConfigs.${target};
      #   })
      # );
    };
}
