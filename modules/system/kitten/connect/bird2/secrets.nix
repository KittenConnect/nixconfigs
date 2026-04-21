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
  peersWithPasswordRef = filterAttrs (n: v: v.passwordRef != null) peers;

  passwords = unique (mapAttrsToList (n: v: v.passwordRef) peersWithPasswordRef);
in {
  # Sops secrets implementation
  config = mkIf cfg.enable {
    # Secrets management
    sops = mkIf (passwords != []) {
      secrets = (
        listToAttrs (
          map (n: nameValuePair "bird_secrets/${n}" {reloadUnits = ["${cfg.serviceName}.service"];}) passwords
        )
      );

      templates."bird_secrets.conf" = mkIf (passwords != []) {
        owner = cfg.user;
        content = (
          mkMerge (
            map (password: ''
              define secretPassword_${password} = "${config.sops.placeholder."bird_secrets/${password}"}";
            '')
            passwords
          )
        );
      };
    };

    # Service configuration
    services.${cfg.serviceName} = {
      preCheckConfig = mkIf (passwords != []) ''
        (
            LINE=$(grep -n include ${cfg.serviceName}.conf | grep bird_secrets.conf | head -1 | cut -d: -f1)
            if [ ! -z "$LINE" ]; then
                echo "Found secrets importing, will substitute it with placeholders values"
                sed ''${LINE}d -i ${cfg.serviceName}.conf
                sed "$(($LINE))i"'include "_secrets_substitute.conf";' -i ${cfg.serviceName}.conf

                cat > _secrets_substitute.conf <<< '
                    ${config.sops.templates."bird_secrets.conf".content}
                '
            fi
        )
      '';

      config = mkIf (passwords != []) (
        mkOrder 5 ''include "${config.sops.templates."bird_secrets.conf".path}";''
      );
    };
  };
}
