{ lib, ... }:
{
  imports = [
    #         ./clients.nix
    #         ./homerouters.nix
    #         ./miscservers.nix
    #         ./postgres.nix
    #         ./routereflectors.nix
    #         ./routers.nix
    #         ./stonkmembers.nix
  ];

  options.kitten.profiles.common = lib.mkEnableOption "Kitten common basic configurations";
}
