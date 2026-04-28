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

  mkFakeMED = x: "define bgpMED_${x} = 2147483647;"; # 2^31 - 1

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
    })

    (mkIf (cfg.autoMED) {
      # Service configuration
      systemd.services.bird-icmp-automed = {
        path = [pkgs.bird2]; # TODO: better pkgs handling
        wants = ["network-online.target"];
        after =
          [
            "network-online.target"
          ]
          ++ (builtins.map (x: "wg-quick-${x}.service") (
            builtins.attrNames config.networking.wg-quick.interfaces
          ));
        before = ["${cfg.serviceName}.service"];

        serviceConfig = {
          Type = "simple";
          User = "bird";
          # SupplementaryGroups = ["bird"];
          AmbientCapabilities = [
            "CAP_NET_RAW"
            "CAP_NET_ADMIN"
          ];
          ExecStart = "${autoMEDPackage}/bin/bird-icmp-automed";
          RuntimeDirectory = "%N";
        };
      };

      systemd.services.${cfg.serviceName} = {
        wants = ["bird-icmp-automed.service"];
        # ''${lib.concatMapStringsSep "\n" mkFakeMED (builtins.attrNames peersWithAutoMED)}
        preStart = ''
          touch /run/bird-icmp-automed/.empty.conf
        '';
      };

      # Bird configuration
      services.${cfg.serviceName} = {
        preCheckConfig = ''
          (
              LINE=$(grep -n include ${cfg.serviceName}.conf | grep -F '/bird-icmp-automed/' | head -1 | cut -d: -f1)
              if [ ! -z "$LINE" ]; then
                  echo "Found autoMED importing, will substitute it with placeholders values"
                  sed ''${LINE}d -i ${cfg.serviceName}.conf
                  sed "$(($LINE))i"'include "_automed_substitute.conf";' -i ${cfg.serviceName}.conf

                  cat > _automed_substitute.conf <<< '
                      ${lib.concatMapStringsSep "\n" mkFakeMED (
            (builtins.attrNames peersWithAutoMED) ++ ["AUTOPEER"]
          )}
                  '
              fi
          )
        '';

        config = mkOrder 5 ''include "/run/bird-icmp-automed/*.conf";'';
      };
    })
  ];
}
