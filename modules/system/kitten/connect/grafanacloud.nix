{
  lib,
  pkgs,
  config,
  sources,
  ...
}: let
  cfg = config.kittenModules.grafana;
in {
  options.kittenModules.grafana = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "use grafanacloud as monitoring solution";
    };

    attributes = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "attributes to passthrough grafana alloy";
    };
  };

  config = lib.mkIf cfg.enable {
    kittenModules.grafana.attributes = {
      systemHash = sources.self.revision;
    };

    virtualisation.vmVariant.systemd.services.alloy.enable = lib.mkForce false;
    services.alloy = {
      enable = true;
      configPath = pkgs.writeText "config.alloy" ''
        // https://kittenconnect.grafana.net/a/grafana-collector-app/fleet-management/fleet-inventory
        remotecfg {
          url = "https://fleet-management-prod-011.grafana.net"
          id = constants.hostname
          poll_frequency = "60s"
          attributes = encoding.from_json(coalesce(``, `${builtins.toJSON cfg.attributes}`))

          basic_auth {
            username = "1625643"
            password = sys.env("GCLOUD_RW_API_KEY")
          }
        }

        prometheus.remote_write "metrics_service" {
          endpoint {
            url = "https://prometheus-prod-65-prod-eu-west-2.grafana.net/api/prom/push"

            basic_auth {
              username = "3175514"
              password = sys.env("GCLOUD_RW_API_KEY")
            }
          }
        }

        loki.write "grafana_cloud_loki" {
          endpoint {
            url = "https://logs-prod-012.grafana.net/loki/api/v1/push"

            basic_auth {
              username = "1583432"
              password = sys.env("GCLOUD_RW_API_KEY")
            }
          }
        }
      '';

      environmentFile = config.sops.secrets.grafana_environment.path;
    };

    sops.secrets.grafana_environment = {
      sopsFile = ../../../../.secrets/_default.yaml;
    };
  };
}
