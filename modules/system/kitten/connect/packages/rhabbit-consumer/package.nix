{
  buildGoModule,
  lib,
  fetchFromGitHub,
  ...
}:
let
  src = lib.cleanSource (fetchFromGitHub {
    owner = "KittenConnect";
    repo = "rh-api";
    rev = "cb33c009e93063f410c2b70e2a09316fed0c494a";
    # hash = "";
    hash = "sha256-AegIzJ7xqOoMrmW8iM2NVWhQWoU2qVs7IUUcYbcvuKw=";
    # ...
  });
in
buildGoModule {
  name = "kittenMQ-consumer";
  inherit src;
  # vendorProxy = true;
  # vendorHash = "";
  vendorHash = "sha256-XE5npxjcTRDmINM2IFS4C9NWfsAYiGs+h4sDIZX8AhU=";

  postInstall = ''
    mv $out/bin/rh-api $out/bin/kittenMQ-consumer
  '';

}
