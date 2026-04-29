{
  lib,
  birdConfig,
  kittenLib,
  pkgs,
  ...
}: let
  inherit (lib) optionalString;
  inherit (kittenLib.strings) indentedLines;
  inherit (kittenLib.network) mkFilter loopbackToRD;
  inherit (builtins) concatStringsSep toJSON;
in
  vrf @ {
    enable,
    name,
    tableID,
    birdTable ? null,
    ipv4 ? {},
    ipv6 ? {},
    ...
  }: let 
    getBirdTable = X: lib.replaceStrings ["%"] [(builtins.toString X)] (
      if birdTable != null
      then birdTable
      else "t%_${name}"
    ); in ''

    # VRF ${name} #${builtins.toString tableID}
    ${lib.concatMapStringsSep "\n" (
      x: let
        family = x.name;
        ipvX = x.value;
        X = builtins.fromJSON (builtins.substring (builtins.stringLength family - 1) 1 family);

        _birdTable = getBirdTable X;
      in ''
        ${optionalString (ipvX != {} && ipvX.enable) ''
          ${lib.optionalString (birdTable == null) "${family} table ${_birdTable};"}

          protocol static STATIC${toString X}_${toString name} {
            ipv${builtins.toString X} { table ${_birdTable}; };
            vrf "${name}";

            ${indentedLines 1 (concatStringsSep "\n" (map (x: "route ${x};") ipvX.static))}
          }
          
          protocol kernel KERNEL${toString X}_${toString name} {
            ${optionalString enable "# "}disabled;
            kernel table ${builtins.toString tableID};
            vrf "${name}";

            ${family} {
              table ${_birdTable};

            ${optionalString (
            ipvX.bgpImports == null || (ipvX.bgpImports != "" && ipvX.bgpImports.allowed != [])
          ) (indentedLines 2 (mkFilter "import" "k${builtins.toString X}_${name}" ipvX.bgpImports))}
            ${optionalString (
            ipvX.bgpExports == null || (ipvX.bgpExports != "" && ipvX.bgpExports.allowed != [])
          ) (indentedLines 2 (mkFilter "export" "k${builtins.toString X}" ipvX.bgpExports))}
            };
          }
        ''}
      ''
    ) (lib.attrsToList {inherit ipv4 ipv6;})}

    # IP <-> VPN translation protocol
    protocol l3vpn l3vpn${name} {
      vrf "${name}";
      ${optionalString (ipv4 != {} && ipv4.enable) ''
        ipv4 { table ${getBirdTable 4}; };
        vpn4 { table vpntab4; };
      ''}
      ${optionalString (ipv6 != {} && ipv6.enable) ''
        ipv6 { table ${getBirdTable 6}; };
        vpn6 { table vpntab6; };
      ''}
      mpls { label policy vrf; };

      # TODO: variabilize
      rd ${lib.concatMapStringsSep ":" builtins.toString (loopbackToRD birdConfig.loopback6)};
      import target [(rt, 4242421945, ${builtins.toString tableID})]; # TODO: mapping rt-VRF
      export target [(rt, 4242421945, ${builtins.toString tableID})]; # TODO: mapping rt-VRF
    }
  ''
