{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  kubeCfg = osConfig.services.k3s;
  cfg = config.kittenModules.kube;
in
{
  options.kittenModules.kube = {
    enable = lib.mkEnableOption "KittenK3s common configuration" // { default = true; example = false; };
  };

  config = lib.mkIf (kubeCfg.enable && kubeCfg.role == "server") {
    home.kubenv.enable = true;
    home.sessionVariables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };
}
