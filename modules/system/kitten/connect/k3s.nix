{ lib, config, pkgs, ... }: let
  inherit (lib) mkOption types mkIf mkMerge optional optionals;

  tokenSecret = if cfg.controller then "k3s_cluster_token" else "k3s_token";

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
        "--cluster-cidr=${cfg.clusterCidr}"
        "--service-cidr=${cfg.serviceCidr}"
        "--disable=servicelb,local-storage,traefik"
      ]
      ++ (optionals (cfg.oidc.issuerUrl != null) [
        "--kube-apiserver-arg oidc-issuer-url=${cfg.oidc.issuerUrl}"
        "--kube-apiserver-arg oidc-client-id=${cfg.oidc.clientId}"
        "--kube-apiserver-arg oidc-username-claim=${cfg.oidc.usernameClaim}"
        "--kube-apiserver-arg oidc-groups-claim=${cfg.oidc.groupsClaim}"
      ])
      ++ (optionals (cfg.etcd.snapshot.schedule != null) [
        "--etcd-snapshot-schedule-cron='${cfg.etcd.snapshot.schedule}'"
        "--etcd-snapshot-retention=${toString cfg.etcd.snapshot.retention}"
      ])
      ++ (optionals (cfg.etcd.snapshot.schedule != null && cfg.etcd.tmpfs) [
        "--etcd-snapshot-dir=/var/lib/rancher/k3s/server/db.persistent/snapshots"
      ])
      ++ (optionals (cfg.etcd.heartbeatInterval != null) [
        "--etcd-arg heartbeat-interval=${toString cfg.etcd.heartbeatInterval}"
      ])
      ++ (optionals (cfg.etcd.electionTimeout != null) [
        "--etcd-arg election-timeout=${toString cfg.etcd.electionTimeout}"
      ])
      ++ (optionals (cfg.etcd.snapshot.schedule != null && cfg.etcd.snapshot.s3.bucket != null) [
        "--etcd-s3"
        "--etcd-s3-endpoint=${cfg.etcd.snapshot.s3.endpoint}"
        "--etcd-s3-region=${cfg.etcd.snapshot.s3.region}"
        "--etcd-s3-bucket=${cfg.etcd.snapshot.s3.bucket}"
      ] ++ optional (cfg.etcd.snapshot.s3.folder != "") "--etcd-s3-folder=${cfg.etcd.snapshot.s3.folder}")
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

    etcd = {
      snapshot = {
        schedule = mkOption {
          type = with types; nullOr str;
          default = "0 * * * *";
          description = "Cron schedule for automatic etcd snapshots";
        };

        retention = mkOption {
          type = types.int;
          default = 12;
          description = "Number of etcd snapshots to retain";
        };

        s3 = {
          endpoint = mkOption {
            type = types.str;
            default = "s3.${cfg.region}.amazonaws.com";
            description = "S3 endpoint URL for etcd snapshots";
          };

          region = mkOption {
            type = types.str;
            default = "eu-west-3"; # La Fronce mossieur
            description = "S3 region for etcd snapshots";
          };

          bucket = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "S3 bucket name for etcd snapshots";
          };

          folder = mkOption {
            type = types.str;
            default = "";
            description = "S3 folder prefix for snapshots";
          };
        };
      };

      heartbeatInterval = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "etcd heartbeat interval in milliseconds (--etcd-arg heartbeat-interval)";
      };

      electionTimeout = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "etcd election timeout in milliseconds (--etcd-arg election-timeout)";
      };

      tmpfs = mkOption {
        type = types.bool;
        default = true;
        description = "Mount /var/lib/rancher/k3s/server/db as tmpfs (server only)";
      };
    };

    oidc = {
      issuerUrl = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "OIDC issuer URL for Kubernetes API authentication";
      };

      clientId = mkOption {
        type = types.str;
        default = "kubeapi";
        description = "OIDC client ID for Kubernetes API authentication";
      };

      usernameClaim = mkOption {
        type = types.str;
        default = "email";
        description = "OIDC username claim";
      };

      groupsClaim = mkOption {
        type = types.str;
        default = "groups";
        description = "OIDC groups claim";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      networking.firewall.allowedUDPPorts = [ 51820 51821 ];

      sops.secrets.${tokenSecret} = {
        sopsFile = ../../../../.secrets/kubernetes.yaml;
      };

      services.k3s = {
        enable = true;
        package = cfg.package;
        role = if cfg.controller then "server" else "agent";

        # hexdump -vn24 -e'6/4 "%08X" 1 "\n"' /dev/urandom
        tokenFile = config.sops.secrets.${tokenSecret}.path;

        clusterInit = cfg.master;

        serverAddr = lib.mkIf (!cfg.master && cfg.serverAddr != null) cfg.serverAddr;

        extraFlags = toString (generalFlags ++ serverFlags);
      };

      environment.systemPackages = [ cfg.package ] ++ deps;

      systemd.services.k3s = {
        path = deps;
      };
    }

    (lib.mkIf (cfg.master && cfg.etcd.tmpfs) {
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
