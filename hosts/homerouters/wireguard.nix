{
  lib,
  pkgs,
  config,

  target,
  targetConfig,
  birdConfig,
  ...
}:
let

  # Imports Functions
  inherit (lib.attrsets)
    filterAttrs
    mapAttrs
    mapAttrsToList
    genAttrs
    zipAttrs
    optionalAttrs
    ;

  inherit (lib.asserts) assertMsg;

  inherit (lib.strings) hasPrefix optionalString;

  inherit (builtins) attrNames;

  # Variables / Functions

  IFACE = if targetConfig ? interface then targetConfig.interface else null;

  peers = filterAttrs (n: v: v ? wireguard && v.wireguard != { }) birdConfig.peers;

  hasPort = (n: v: v.wireguard ? port);
  hasIface = (n: v: v.wireguard ? onIFACE);

  peersWithPort = filterAttrs hasPort peers;

  peersWithoutIFACE = filterAttrs (n: v: (!hasIface n v)) peersWithPort;
  peersWithIFACE = filterAttrs hasIface peersWithPort;

  portsWithoutIFACE = mapAttrsToList (n: v: v.wireguard.port) peersWithoutIFACE;
  portsWithIFACE = zipAttrs (
    mapAttrsToList (n: v: { ${v.wireguard.onIFACE} = v.wireguard.port; }) peersWithIFACE
  );

  mkFWConf = ports: { allowedUDPPorts = ports; };

  genFWMarkStr = (
    mark:
    {
      "string" =
        assert assertMsg (hasPrefix "0x" mark) "fwMark is string but does not start with 0x is it an int ?";
        mark;

      "int" = toString mark;

      "null" = null;
    }
    .${builtins.typeOf mark}

  );

  mkWireguardConf =
    name:
    let
      peer = peers.${name};

      fwMarkString = (
        let
          mark =
            if peer.wireguard ? fwMark then
              peer.wireguard.fwMark

            else if (peer.wireguard ? onIFACE && peer.wireguard.onIFACE != null) then
              peer.wireguard.port

            else
              null;
        in
        genFWMarkStr mark

      );
    in
    {
      table = "off";
      # Determines the IP/IPv6 address and subnet of the client's end of the tunnel interface
      address = [ "${peer.wireguard.address}/127" ];
      # The port that WireGuard listens to - recommended that this be changed from default
      listenPort = lib.mkIf (peer.wireguard ? port) peer.wireguard.port;

      postUp = ''
        ${optionalString (fwMarkString != null) "wg set ${name} fwmark ${fwMarkString}"}
      '';

      # Path to the server's private key
      privateKeyFile = config.sops.secrets.wireguard_serverkey.path;

      peers = [
        {
          publicKey = peer.wireguard.peerKey;
          #presharedKeyFile = "/root/wireguard-keys/preshared_from_peer0_key";
          persistentKeepalive = 10;
          endpoint = lib.mkIf (peer.wireguard ? endpoint) peer.wireguard.endpoint;

          allowedIPs = [
            "0.0.0.0/0"
            "::/0"
          ];
        }
      ];
    };
in
{
  #  sops --set '["wireguard_serverkey"] "'"$(wg genkey | tee >(wg pubkey > /dev/stderr))"'"' secrets/<name>.yaml
  sops.secrets.wireguard_serverkey = { };
  environment.systemPackages = with pkgs; [ wireguard-tools ];

  # Open FireWall Ports
  networking.firewall = lib.mkMerge [
    (optionalAttrs (portsWithoutIFACE != [ ]) (
      let
        conf = mkFWConf portsWithoutIFACE;
      in
      if IFACE != null then { interfaces.${IFACE} = conf; } else conf
    ))

    (optionalAttrs (portsWithIFACE != { }) {
      interfaces = (mapAttrs (name: value: mkFWConf value) portsWithIFACE);
    })
  ];

  networking.wg-quick.interfaces = mapAttrs mkWireguardConf config.peers;
}
