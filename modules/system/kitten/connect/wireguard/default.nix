{
  lib,
  pkgs,
  config,
  target,
  targetConfig,
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

  inherit (lib.strings) hasPrefix optionalString concatMapStringsSep;

  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    mkMerge
    types
    ;

  inherit (builtins) attrNames;

  # Variables / Functions

  cfg = config.kittenModules.wireguard;
  IFACE = if targetConfig ? interface then targetConfig.interface else null;

  peers = cfg.peers;

  hasPort = (n: v: v.port != null);
  hasIface = (n: v: v.onIFACE != null);

  peersWithPort = filterAttrs hasPort peers;

  peersWithoutIFACE = filterAttrs (n: v: (!hasIface n v)) peersWithPort;
  peersWithIFACE = filterAttrs hasIface peersWithPort;

  portsWithoutIFACE = mapAttrsToList (n: v: v.port) peersWithoutIFACE;
  portsWithIFACE = zipAttrs (mapAttrsToList (n: v: { ${v.onIFACE} = v.port; }) peersWithIFACE);

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
    name: peer:
    let
      fwMarkString = (
        let
          mark =
            if peer.fwMark != null then
              peer.fwMark
            else if (peer.onIFACE != null) then
              peer.port
            else
              null;
        in
        genFWMarkStr mark
      );
    in
    {
      table = "off";
      # Determines the IP/IPv6 address and subnet of the client's end of the tunnel interface
      address = [ "${peer.address}/127" ];
      # The port that WireGuard listens to - recommended that this be changed from default
      listenPort = mkIf (peer.port != null) peer.port;

      postUp = ''

        set - x

        ${optionalString (fwMarkString != null) "wg set ${name} fwmark ${fwMarkString}"}
        ${optionalString (peer.onIFACE != null) ''

          echo "TABLE=${fwMarkString}"
          for v in 4 6; do
            echo "[#] IPv$v"
            ip -$v route add unreachable default metric 4294967295 table ${fwMarkString} || true
            ip -$v route add default $(ip -$v route show default dev ${peer.onIFACE} | grep -oE 'via [^ ]+') dev ${peer.onIFACE} metric 42 table ${fwMarkString} || true
            ip -$v rule add fwmark ${fwMarkString} lookup main suppress_prefixlength 0
            ip -$v rule add fwmark ${fwMarkString} lookup ${fwMarkString}
          done
        ''}
      '';

      postDown = ''

        set -x

        ${optionalString (peer.onIFACE != null) ''

          echo "TABLE=${fwMarkString}"
          for v in 4 6; do
            echo "[#] IPv$v"
            # ip -$v route del unreachable default metric 4294967295 table ${fwMarkString} || true
            ip -$v route del default metric 42 table ${fwMarkString} || true
            while ip -$v rule del fwmark ${fwMarkString} lookup main suppress_prefixlength 0; do echo -n .; sleep 0.1; done
            while ip -$v rule del fwmark ${fwMarkString} lookup ${fwMarkString}; do echo -n .; sleep 0.1; done
          done
        ''}
      '';

      # Path to the server's private key
      privateKeyFile = config.sops.secrets.wireguard_serverkey.path;

      peers = [
        {
          publicKey = peer.peerKey;
          #presharedKeyFile = "/root/wireguard-keys/preshared_from_peer0_key";
          persistentKeepalive = 10;
          endpoint = mkIf (peer.endpoint != null) peer.endpoint;

          allowedIPs = [
            "0.0.0.0/0"
            "::/0"
          ];
        }
      ];
    };
in
{

  # Options
  options.kittenModules.wireguard = {
    enable = mkEnableOption "Kitten Wireguard module";
    allowFirewall = mkEnableOption "automatic firewall rules creation";

    peers = mkOption {
      default = { };
      description = "WireGuard peers configuration.";
      type = types.attrsOf (
        types.submodule (
          { name, config, ... }:
          {
            options = {
              address = mkOption {
                type = types.str;
                description = "IP/IPv6 address and subnet of the client's end of the tunnel interface.";
              };
              port = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "The port that WireGuard listens to.";
              };
              fwMark = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Firewall mark for the WireGuard interface.";
              };
              onIFACE = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Interface name for the WireGuard interface.";
              };
              peerKey = mkOption {
                type = types.str;
                description = "Public key of the WireGuard peer.";
              };
              endpoint = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Endpoint for the WireGuard peer.";
              };
            };
          }
        )
      );
    };
  };

  config = mkIf (cfg.enable) {
    _module.args = {
      wgPeers = peers;
    };

    #  sops --set '["wireguard_serverkey"] "'"$(wg genkey | tee >(wg pubkey > /dev/stderr))"'"' secrets/[HOSTNAME].yaml
    sops.secrets.wireguard_serverkey = { };
    environment.systemPackages = with pkgs; [ wireguard-tools ];

    environment.etc."iproute2/rt_tables.d/wgnix.conf" = mkIf (peers != [ ]) {
      text = ''

        ${concatMapStringsSep "\n" (
          peerName:
          let
            peer = peers.${peerName};
          in
          "${toString peer.port} ${peerName}"
        ) (attrNames (filterAttrs (n: v: v.onIFACE != null) peers))}
      '';
    };

    # Open FireWall Ports
    networking.firewall = mkMerge [
      (optionalAttrs (portsWithoutIFACE != [ ]) (
        let
          conf = mkFWConf portsWithoutIFACE;
        in
        if IFACE != null then { interfaces.${IFACE} = conf; } else conf
      ))

      (optionalAttrs (portsWithIFACE != [ ]) {
        interfaces = (mapAttrs (name: value: mkFWConf value) portsWithIFACE);
      })
    ];

    # networking.wg-quick.interfaces = genAttrs (attrNames peers) mkWireguardConf;
    networking.wg-quick.interfaces = mapAttrs mkWireguardConf cfg.peers;
  };
}
