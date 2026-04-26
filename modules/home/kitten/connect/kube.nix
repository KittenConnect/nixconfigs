{
  pkgs,
  lib,
  config,
  options,
  osConfig,
  ...
}: let
  kubeCfg = osConfig.services.k3s;
  cfg = config.kittenHome.kube;
in {
  options.kittenHome.kube = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "KittenK3s common configuration";
    };
  };

  config = lib.optionalAttrs (kubeCfg.enable && kubeCfg.role == "server" && options.home ? kubenv) {
    home.kubenv.enable = true;
    home.sessionVariables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };
}
