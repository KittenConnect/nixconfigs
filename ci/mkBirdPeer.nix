let
  inherit (import ../default.nix {}) inputs;
  peer = builtins.fromJSON (builtins.readFile /dev/stdin);

  example = ''
    {
    "enable": true,
    "interface": "wg0",
    "peerName": "toto",
    "peerIP": "1.2.3.4",
    "peerAS": 65535,
    "localIP": "1.2.3.2",
    "localAS": 65535,
    "password": null,
    "passwordRef": null,
    "multihop": 0,
    "bgpMED": 0,
    "ipv4": {},
    "ipv6": {},
    "template": null
    }
  '';
in
  import ../modules/system/kitten/connect/bird2/peer_config.nix {
    inherit (inputs) pkgs lib kittenLib;
    inherit peer;
  }
