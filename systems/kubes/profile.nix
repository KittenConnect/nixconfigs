{
  lib,
  pkgs,
  config,
  ...
}:
{
  kittenModules.k3s = {
    enable = true;
    master = true;
    controller = true;
    serverAddr = null; # TODO: find one
    flannelIface = lib.mkDefault "vlan91";
    clusterCidr = "10.42.0.0/16,fd42::/48";
    serviceCidr = "10.43.0.0/16,fd43::/112";

    extraServerFlags = [
      "--flannel-ipv6-masq"
      "--secrets-encryption"
    ];

    oidc = {
      issuerUrl = "https://auth.home.kube.kittenconnect.net/";
      clientId = "KubernetesAPIClient";
    };

    etcd = {
      tmpfs = lib.mkDefault true;
      snapshot = {
        s3 = {
          endpoint = "s3.svc.kittencorp.net";
          region = "home-nas";
          bucket = "s3bakoup";
          folder = "stonkster_etcd";
        };
      };
    };
  };

  services.resolved.enable = false;
  networking.nameservers = [
    "1010:cafe:ffff:fefe::53"
    # "1010:cafe:ffff:fefe::5353"
    # "2620:fe::fe"
    # "9.9.9.9"
  ];
  networking.resolvconf.extraConfig = ''
    name_servers="${lib.concatStringsSep " " config.networking.nameservers}"
  '';
}

# {
#   lib,
#   pkgs,
#   ...
# }: {
#   kittenModules.k3s = {
#     enable = true;
#     master = true;
#     controller = true;
#     serverAddr = null;
#     package = pkgs.k3s;
#     extraFlags = [];
#     extraServerFlags = [
#       "--flannel-ipv6-masq"
#       "--secrets-encryption"
#     ];
#     flannelIface = lib.mkDefault "vlan91";
#     clusterCidr = "10.42.0.0/16,fd42::/48";
#     serviceCidr = "10.43.0.0/16,fd43::/112";
#     oidc = {
#       issuerURL = "https://auth.home.kube.kittenconnect.net/";
#       clientId = "KubernetesAPIClient";
#     };
#     enableTmpfsDb = true;
#     etcdSnapshot = {
#       enable = true;
#       schedule = "0 * * * *";
#       retention = 12;
#       s3 = {
#         enable = true;
#         endpoint = "s3.svc.kittencorp.net";
#         region = "home-nas";
#         bucket = "s3bakoup";
#         folder = "stonkster_etcd";
#       };
#     };
#   };
# }
