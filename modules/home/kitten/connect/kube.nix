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
      default = kubeCfg.enable && kubeCfg.role == "server";
      example = false;
      description = "KittenK3s common configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  }
  // lib.optionalAttrs (options.home ? kubenv) {
    home.kubenv.enable = true;
  };
}
