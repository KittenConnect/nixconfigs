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
    enable =
      lib.mkEnableOption "KittenK3s common configuration"
      // {
        default = true;
        example = false;
      };
  };

  config = lib.optionalAttrs (kubeCfg.enable && kubeCfg.role == "server" && options.home ? kubenv) {
    home.kubenv.enable = true;
    home.sessionVariables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };
}
