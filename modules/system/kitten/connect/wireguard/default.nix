{
  lib,
  pkgs,
  config,
  ...
}:
let
  # Imports Functions
  inherit (lib.attrsets)
    filterAttrs
    mapAttrs
    mapAttrs'
    mapAttrsToList
    genAttrs
    zipAttrs
    optionalAttrs
    ;

  inherit (lib.asserts) assertMsg;

  inherit (lib.strings) hasPrefix optionalString concatMapStringsSep;

  inherit (lib)
    mkOption
    mkIf
    mkMerge
    types
    ;

  inherit (builtins) attrNames;

  # Variables / Functions

  cfg = config.kittenModules.wireguard;
  # IFACE = if targetConfig ? interface then targetConfig.interface else null;

  peers = cfg.peers;

  hasPort = n: v: v.port != null;
  hasIface = n: v: v.onIFACE != null;

  quoteString = s: ''"${builtins.toString s}"'';

  peersWithPort = filterAttrs hasPort peers;

  peersWithoutIFACE = filterAttrs (n: v: (!hasIface n v)) peersWithPort;
  peersWithIFACE = filterAttrs hasIface peersWithPort;

  ifacesWithPeers = lib.foldl (
    acc:
    { name, value }:
    acc
    // {
      ${value.onIFACE} = (acc.${value.onIFACE} or { }) // {
        ${name} = value;
      };
    }
  ) { } (lib.attrsToList peersWithIFACE);

  portsWithoutIFACE = mapAttrsToList (n: v: v.port) peersWithoutIFACE;
  portsWithIFACE = zipAttrs (mapAttrsToList (n: v: { ${v.onIFACE} = v.port; }) peersWithIFACE);

  mkFWConf = ports: { allowedUDPPorts = ports; };

  getMark =
    peer:
    if peer.fwMark != null then
      peer.fwMark
    else if peer.onIFACE != null then
      peer.port + 85458944 # all FWMark are 0x518xxxxx
    else
      null;
in
{
  # Options
  options.kittenModules.wireguard = import ./options.nix { inherit (lib) mkOption types; } cfg;

  config = mkIf (cfg.enable) {
    _module.args = {
      wgPeers = peers;
    };

    boot.kernelPatches = [
      {
        name = "wireguard-mpls";
        patch = ./wireguard-mpls-${config.boot.kernelPackages.kernel.name}.patch;
      }
    ];

    #  sops --set '["wireguard_serverkey"] "'"$(wg genkey | tee >(wg pubkey > /dev/stderr))"'"' secrets/[HOSTNAME].yaml
    sops.secrets.wireguard_serverkey = {
      mode = "0440";
      group = "systemd-network";
    };
    environment.systemPackages = with pkgs; [ wireguard-tools ];
    systemd.services.systemd-networkd = {
      reloadTriggers = [ config.sops.secrets.wireguard_serverkey.path ];
      wants = ["systemd-udev-settle.service"];
    };
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
        # let
        #   conf = mkFWConf portsWithoutIFACE;
        # in
        # if IFACE != null then { interfaces.${IFACE} = conf; } else conf
        mkFWConf portsWithoutIFACE
      ))

      (optionalAttrs (portsWithIFACE != [ ]) {
        interfaces = mapAttrs (name: value: mkFWConf value) portsWithIFACE;
      })
    ];
    kittenModules.firewall.forward = lib.mkIf (config.kittenModules.firewall.forward.enable) {
      sets.kittenIFACEs = {
        setType = "ifname";
        elements = builtins.attrNames peers;
      };
    };

    systemd.network = {
      netdevs = mapAttrs' (
        peerName: peer:
        lib.nameValuePair "60-${peerName}" {
          netdevConfig = {
            Kind = "wireguard";
            Name = peerName;
          };

          wireguardConfig =
            let
              mark = getMark peer;
            in
            {
              PrivateKeyFile = lib.mkDefault config.sops.secrets.wireguard_serverkey.path;
            }
            // (lib.optionalAttrs (mark != null) { FirewallMark = mark; })
            // (lib.optionalAttrs (peer.port != null) { ListenPort = peer.port; });
          # onIFACE = "vlan666";

          wireguardPeers = [
            {
              AllowedIPs = [
                "0.0.0.0/0"
                "::/0"
              ];

              Endpoint = mkIf (peer.endpoint != null) peer.endpoint;
              PersistentKeepalive = 10;
              PublicKey = peer.peerKey;
            }
          ];
        }
      ) cfg.peers;

      networks = mapAttrs' (
        peerName: peer:
        lib.nameValuePair "70-${peerName}" {
          matchConfig = {
            Name = peerName;
          };

          # Determines the IP/IPv6 address and subnet of the client's end of the tunnel interface
          address =
            let
              mask = if lib.hasPrefix "fe80:" peer.address then 64 else 127;
              addrMask =
                if lib.hasInfix "/" peer.address then peer.address else "${peer.address}/${builtins.toString mask}";
            in
            [ addrMask ];

          networkConfig = {
            BindCarrier = lib.mkIf (peer.onIFACE != null) peer.onIFACE;
          };
          extraConfig = ''
            [Network]
            MPLSRouting = ${if peer.mpls then "yes" else "no"}
          ''; # option is available on nixos-unstable

          routes = lib.mkIf (peer.onIFACE != null) [
            {
              Table = getMark peer;
              Destination = "0.0.0.0/0";
              Type = "unreachable";
              Metric = 4294967295;
            }
            {
              Table = getMark peer;
              Destination = "::0/0";
              Type = "unreachable";
              Metric = 4294967295;
            }
          ];

          routingPolicyRules = lib.mkIf (peer.onIFACE != null) [
            {
              Family = "both";
              FirewallMark = getMark peer;
              Table = getMark peer; # We then put the underlay routes in this table
            }

            {
              Family = "both";
              FirewallMark = getMark peer;
              Table = "main"; # Cheat code to avoid duplicating half our routes
              SuppressPrefixLength = 0; # seems to break when "unreachable / blackhole" default
            }
          ];

          # onIface vlan666
          vrf = lib.optional (peer.vrf != null) peer.vrf;
        }
      ) cfg.peers;
    };

    services.networkd-dispatcher =
      let
        mkDispatchScript = commands: ''
          set -x
          export PATH="${
            lib.makeBinPath (
              with pkgs;
              [
                gawk
                iproute2
                gnugrep
              ]
            )
          }:''${PATH:-/run/current-system/sw/bin}"

          if [[ "''${AdministrativeState:-}" == "configured" ]]; then
            case $IFACE in
          ${concatMapStringsSep "\n" (
            { name, value }:
            ''
              ${name})
                # shellcheck disable=SC2034
                onIFACE="${name}"
                # shellcheck disable=SC2034
                ifaceVRF=$(ip -d link show "$onIFACE" | grep -oE 'vrf_slave table ([^ ]+)' | awk '{ print $NF }' || echo main)

                for p in ${
                  concatMapStringsSep " " (peer: "${peer.name}=${builtins.toString (getMark peer.value)}") (
                    lib.attrsToList value
                  )
                }; do
                  # shellcheck disable=SC2034
                  peerName="$(cut -d= -f1 <<< "$p")"
                  # shellcheck disable=SC2034
                  fwMark="$(cut -d= -f2 <<< "$p")"
                  if ! (
                    ${commands}
                  ); then
                    echo "Failed to setup $peerName" >&2
                  fi
                done
              ;;
            ''
          ) (lib.attrsToList ifacesWithPeers)}
                *)
                  echo "unknown peer... doing nothing" >&2
                ;;
            esac
          fi
          exit 0
        '';
      in
      {
        enable = true;

        rules = {
          "wgmark-up" = {
            onState = [ "configured" ];
            script = mkDispatchScript ''
              for v in 4 6; do
                echo "[#] IPv$v"
                ip -$v route show default dev "$onIFACE" table "$ifaceVRF" | grep -oE 'via [^ ]+' | xargs -I% ${pkgs.runtimeShell} -xc \
                  "ip -$v route change default metric 42 table $fwMark % dev $onIFACE || ip -$v route add default metric 42 table $fwMark % dev $onIFACE"
              done
            '';
          };

          "wgmark-down" = {
            onState = [ "off" ];

            script = mkDispatchScript ''
              for v in 4 6; do
                echo "[#] IPv$v"
                ip "-$v" route delete default metric 42 table "$fwMark" dev "$onIFACE" || true
              done
            '';
          };
        };

      };
  };
}
