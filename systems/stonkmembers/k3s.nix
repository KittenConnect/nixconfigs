{
  config,
  kubeConfig,
  lib,
  pkgs,
  ...
}:

let
  deps = with pkgs; [
    ipset
    iptables
    nfs-utils
    miniupnpc
  ];

  sopsFile = ../../secrets/_default.yaml;
in
{
  sops.secrets.k3s_cluster_token = {
    inherit sopsFile;
  };

  sops.secrets.k3s_token = {
    inherit sopsFile;
  };

  services.k3s = {
    enable = true;
    role = if kubeConfig.controller then "server" else "agent";

    tokenFile =
      if kubeConfig.controller then
        config.sops.secrets.k3s_cluster_token.path
      else
        config.sops.secrets.k3s_token.path;
    clusterInit = kubeConfig.master;
    #serverAddr = lib.mkIf (master == false) "https://[2a13:79c0:ffff:feff:b00b:3945:a51:210]:6443";
    serverAddr = lib.mkIf (!kubeConfig.master) "https://stonkstation:6443";
    extraFlags = toString (
      [ "--flannel-iface=vlan91" ]
      ++ lib.optionals (kubeConfig.controller) [
        #      "--kubelet-arg=v=4" # Optionally add additional args to k3s
        "--kubelet-arg=container-log-max-files=5"
        "--kubelet-arg=container-log-max-size=10Mi"
        "--kube-apiserver-arg enable-admission-plugins=PodNodeSelector,CertificateApproval,CertificateSigning,CertificateSubjectRestriction,DefaultIngressClass,DefaultStorageClass,DefaultTolerationSeconds,LimitRanger,MutatingAdmissionWebhook,NamespaceLifecycle,PersistentVolumeClaimResize,PodSecurity,Priority,ResourceQuota,RuntimeClass,ServiceAccount,StorageObjectInUseProtection,TaintNodesByCondition,ValidatingAdmissionPolicy,ValidatingAdmissionWebhook"
        "--kube-apiserver-arg oidc-issuer-url=https://auth.home.kube.kittenconnect.net/"
        "--kube-apiserver-arg oidc-client-id=KubernetesAPIClient"
        "--kube-apiserver-arg oidc-username-claim=email"
        "--kube-apiserver-arg oidc-groups-claim=groups"
        "--cluster-cidr=10.42.0.0/16,fd42::/48"
        "--service-cidr=10.43.0.0/16,fd43::/112"
        "--flannel-ipv6-masq"
        "--flannel-backend=wireguard-native"
        "--flannel-external-ip"

        "--disable=servicelb,local-storage,traefik"
        "--secrets-encryption"
      ]
    );
  };

  environment.systemPackages = [ pkgs.k3s ] ++ deps;
  systemd.services.k3s.path = deps;
}
