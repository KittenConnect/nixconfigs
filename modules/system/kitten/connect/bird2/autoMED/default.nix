args @ {
  lib,
  kittenLib,
  pkgs,
  config,
  name,
  ...
}: let
  inherit
    (lib)
    mkOrder
    filterAttrs
    listToAttrs
    nameValuePair
    mkMerge
    mkIf
    unique
    mapAttrsToList
    ;

  # Main config is here
  cfg = config.kittenModules.bird;

  # Values
  peers = cfg.peers;
  peersWithAutoMED = filterAttrs (n: v: v.bgpMED == -1) peers;

  autoMEDPath = "/run/bird_automed.conf";
  autoMEDPackage = pkgs.callPackage ./package.nix {};
in {
  # Sops secrets implementation
  config = lib.mkMerge [
    (mkIf (!cfg.autoMED) {
      assertions = [
        {
          assertion = peersWithAutoMED == {};
          message = "Cannot have peers with MED == -1 (autoMED) if config.kittenModules.bird.automed daemon is disabled";
        }
      ];
      # throw "TODO: implement auto bgpMED"
    })

    (mkIf (cfg.autoMED) {
      # Service configuration
      systemd.services.bird-icmp-automed = {
        path = [pkgs.bird2]; # TODO: better pkgs handling
        wants = ["network-online.target"];
        after = ["network-online.target"];
        before = ["${cfg.serviceName}.service"];

        serviceConfig = {
          Type = "simple";
          SupplementaryGroups = ["bird"];
          AmbientCapabilities = ["CAP_NET_RAW" "CAP_NET_ADMIN"];
          ExecStart = "${autoMEDPackage}/bin/bird-icmp-automed ${autoMEDPath}";
        };
      };

      # Bird configuration
      services.${cfg.serviceName} = {
        preCheckConfig = ''
          (
              LINE=$(grep -n include ${cfg.serviceName}.conf | grep ${autoMEDPath} | head -1 | cut -d: -f1)
              if [ ! -z "$LINE" ]; then
                  echo "Found autoMED importing, will substitute it with placeholders values"
                  sed ''${LINE}d -i ${cfg.serviceName}.conf
                  sed "$(($LINE))i"'include "_automed_substitute.conf";' -i ${cfg.serviceName}.conf

                  cat > _automed_substitute.conf <<< '
                      ${lib.concatMapStringsSep "\n" (x: ''define bgpMED_${x} = 999999;'') (builtins.attrNames peersWithAutoMED)}
                  '
              fi
          )
        '';

        config = mkOrder 5 ''include "${autoMEDPath}";'';
      };
    })
  ];
}
