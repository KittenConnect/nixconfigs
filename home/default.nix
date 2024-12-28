{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  kubeCfg = osConfig.services.k3s;
in
{
  imports = [ ] ++ lib.optional (kubeCfg.enable && kubeCfg.role == "server") ./kube.nix;
}
