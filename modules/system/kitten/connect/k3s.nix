{ lib, config, pkgs, ... }: let
  inherit (lib) mkOption types mkIf mkMerge optionals;

  cfg = config.kittenModules.k3s;

  flannelFlags = [
    "--flannel-iface=${cfg.flannelIface}"
  ];

  generalFlags = flannelFlags ++ cfg.extraFlags;

  serverFlags =
    if cfg.controller then
      [
        "--kubelet-arg=container-log-max-files=5"
        "--kubelet-arg=container-log-max-size=10Mi"
        "--kube-apiserver-arg oidc-issuer-url=https://auth.home.kube.kittenconnect.net/"
        "--kube-apiserver-arg oidc-client-id=KubernetesAPIClient"
        "--kube-apiserver-arg oidc-username-claim=email"
        "--kube-apiserver-arg oidc-groups-claim=groups"
        "--cluster-cidr=${cfg.clusterCidr}"
        "--service-cidr=${cfg.serviceCidr}"
        "--flannel-ipv6-masq"
        "--disable=servicelb,local-storage,traefik"
        "--secrets-encryption"
      ]
      ++ optionals cfg.etcdSnapshot.enable [
        "--etcd-snapshot-schedule-cron='${cfg.etcdSnapshot.schedule}'"
        "--etcd-snapshot-retention=${toString cfg.etcdSnapshot.retention}"
      ]
      ++ optionals (cfg.etcdSnapshot.enable && cfg.enableTmpfsDb) [
        "--etcd-snapshot-dir=/var/lib/rancher/k3s/server/db.persistent/snapshots"
      ]
      ++ optionals (cfg.etcdSnapshot.enable && cfg.etcdSnapshot.s3.enable) [
        "--etcd-s3"
        "--etcd-s3-endpoint=${cfg.etcdSnapshot.s3.endpoint}"
        "--etcd-s3-region=${cfg.etcdSnapshot.s3.region}"
        "--etcd-s3-bucket=${cfg.etcdSnapshot.s3.bucket}"
        "--etcd-s3-folder=${cfg.etcdSnapshot.s3.folder}"
      ]
      ++ cfg.extraServerFlags
    else
      [];

  deps = with pkgs; [ ipset iptables nfs-utils miniupnpc ];
in {
  options.kittenModules.k3s = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable k3s configuration";
    };

    master = mkOption {
      type = types.bool;
      default = false;
      description = "Whether this node initializes the cluster";
    };

    controller = mkOption {
      type = types.bool;
      default = false;
      description = "Whether this node is a server (true) or agent (false)";
    };

    serverAddr = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Server address for agent nodes to connect to";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.k3s;
      description = "k3s package to use";
    };

    flannelIface = mkOption {
      type = types.str;
      default = "vlan91";
      description = "Flannel interface to use for pod networking";
    };

    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra command-line flags for k3s (applied to all nodes)";
    };

    extraServerFlags = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra flags applied only to server nodes";
    };

    clusterCidr = mkOption {
      type = types.str;
      default = "10.42.0.0/16,fd42::/48";
      description = "Cluster pod CIDR";
    };

    serviceCidr = mkOption {
      type = types.str;
      default = "10.43.0.0/16,fd43::/112";
      description = "Cluster service CIDR";
    };

    etcdSnapshot = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable automatic etcd snapshots";
      };

      schedule = mkOption {
        type = types.str;
        default = "0 * * * *";
        description = "Cron schedule for automatic etcd snapshots";
      };

      retention = mkOption {
        type = types.int;
        default = 12;
        description = "Number of etcd snapshots to retain";
      };

      s3 = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable S3 storage for etcd snapshots";
        };

        endpoint = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "S3 endpoint URL for etcd snapshots";
        };

        region = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "S3 region for etcd snapshots";
        };

        bucket = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "S3 bucket name for etcd snapshots";
        };

        folder = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "S3 folder prefix for snapshots";
        };
      };
    };

    enableTmpfsDb = mkOption {
      type = types.bool;
      default = true;
      description = "Mount /var/lib/rancher/k3s/server/db as tmpfs (server only)";
    };

    sops = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Configure sops secrets for k3s tokens";
      };

      sopsFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to the sops file containing k3s secrets";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      networking.firewall.allowedUDPPorts = [ 51820 51821 ];

      services.k3s = {
        enable = true;
        package = cfg.package;
        role = if cfg.controller then "server" else "agent";

        tokenFile = lib.mkIf cfg.sops.enable (
          if cfg.controller then
            config.sops.secrets.k3s_cluster_token.path
          else
            config.sops.secrets.k3s_token.path
        );

        clusterInit = cfg.master;

        serverAddr = lib.mkIf (!cfg.master && cfg.serverAddr != null) cfg.serverAddr;

        extraFlags = toString (generalFlags ++ serverFlags);
      };

      environment.systemPackages = [ cfg.package ] ++ deps;

      systemd.services.k3s = {
        path = deps;
      };
    }

    (lib.mkIf cfg.sops.enable {
      sops.secrets.k3s_cluster_token = {
        sopsFile = cfg.sops.sopsFile;
      };

      sops.secrets.k3s_token = {
        sopsFile = cfg.sops.sopsFile;
      };
    })

    (lib.mkIf (cfg.master && cfg.enableTmpfsDb) {
      fileSystems."/var/lib/rancher/k3s/server/db" = {
        fsType = "tmpfs";
        options = [
          "size=1G"
          "nosuid"
          "mode=700"
        ];
      };

      systemd.services.k3s = {
        preStart = ''
          if ! [[ -d /var/lib/rancher/k3s/server/db/etcd ]]; then
            ${pkgs.rsync}/bin/rsync -arvp --exclude=snapshots --delete /var/lib/rancher/k3s/server/db.persistent/ /var/lib/rancher/k3s/server/db/
          fi
          mkdir -vp /var/lib/rancher/k3s/server/db.persistent/snapshots
        '';

        preStop = ''
          k3s etcd-snapshot save --etcd-snapshot-dir /var/lib/rancher/k3s/server/db.persistent/snapshots --name on-stop
        '';

        postStop = ''
          ${pkgs.rsync}/bin/rsync -arvp --exclude=snapshots --delete /var/lib/rancher/k3s/server/db/ /var/lib/rancher/k3s/server/db.persistent/
        '';
      };
    })
  ]);
}
