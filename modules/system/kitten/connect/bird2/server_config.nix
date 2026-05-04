{
  lib,
  kittenLib,
  config,
  birdFuncs,
  ...
}: let
  inherit
    (lib)
    optional
    optionals
    optionalString
    mkOrder
    mkMerge
    attrNames
    filterAttrs
    concatStringsSep
    concatMapStringsSep
    ;

  inherit (kittenLib.strings) indentedLines;

  inherit (birdFuncs) quotedString;

  birdCfg = config.services.${srvCfg.serviceName};
  srvCfg = config.kittenModules.bird;

  rrs = attrNames (filterAttrs (n: v: v ? template && v.template == "rrserver") srvCfg.peers);
  RRs = "${concatMapStringsSep " || " (x: "proto = ${quotedString x}") rrs}";

  setLoopBackSRC = nets: loopback: ''
    if source ~ [RTS_BGP] || net ~ [ ${nets} ] then {
      krt_prefsrc=${loopback};
    }'';
in {
  services.${srvCfg.serviceName}.config = mkOrder 25 ''
    function is_rr_proto() {
      return ${
      if (rrs != [])
      then "${RRs}"
      else "false"
    };
    }

    # The Kernel protocol is not a real routing protocol. Instead of communicating
    # with other routers in the network, it performs synchronization of BIRD
    # routing tables with the OS kernel. One instance per table.
    protocol kernel KERNEL4 {
      ipv4 {
        export filter {
          if (net = 0.0.0.0/0 && dest = RTD_UNREACHABLE) then reject;
          if (source !~ [RTS_DEVICE] && (source = RTS_STATIC || is_kitten4_network() || is_rr_proto())) then {
    ${optionalString (srvCfg.loopback4 != null && srvCfg.loopback4 != "") (
      indentedLines 4 (setLoopBackSRC "0.0.0.0/0" srvCfg.loopback4)
    )}
              accept;
          } else reject;
        };
      };
      merge paths on;
    }

    # Another instance for IPv6, skipping default options
    protocol kernel KERNEL6 {
      ipv6 {
        export filter {
          if (net = ::/0 && dest = RTD_UNREACHABLE) then reject;
          if (source !~ [RTS_DEVICE] && (source = RTS_STATIC || is_kitten6_network() || is_rr_proto())) then {
    ${optionalString (srvCfg.loopback6 != null && srvCfg.loopback6 != "") (
      indentedLines 4 (setLoopBackSRC "::/0" srvCfg.loopback6)
    )}
            accept;
          } else reject;
        };
      };
      merge paths on;
    }
  '';
}
