{ kittenLib, ... }:
kittenLib.peers {
  host = ./.;
  profile = ../..;

  blacklist = [ ];
  manual = { };
}
