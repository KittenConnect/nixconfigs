{mkOption, types, ...}: cfg: {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Kitten Wireguard module";
    };
    allowFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "automatic firewall rules creation";
    };

    defaultIFACE = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "default interface name for the WireGuard interface.";
    };

    peers = mkOption {
      default = {};
      description = "WireGuard peers configuration.";
      type = types.attrsOf (
        types.submodule (
          {
            name,
            config,
            ...
          }: {
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
              vrf = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "VRF parent interface to set for this peer.";
              };
              mpls = mkOption {
                type = types.bool;
                default = config.vrf == null;
                description = "use Kitten mpls Wireguard module on this link";
              };
              fwMark = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Firewall mark for the WireGuard interface.";
              };
              onIFACE = mkOption {
                type = types.nullOr types.str;
                default = cfg.defaultIFACE;
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
  }