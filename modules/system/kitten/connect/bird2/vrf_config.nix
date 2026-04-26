{
  lib,
  kittenLib,
  pkgs,
  ...
}: let
  inherit (lib) optionalString;
  inherit (kittenLib.strings) indentedLines;
  inherit (kittenLib.network) mkFilter;
  inherit (builtins) concatStringsSep toJSON;
in vrf@{ enable, name, tableID, birdTable ? null, ipv4 ? {}, ipv6 ? {}, ...}: ''

  # VRF ${name} #${builtins.toString tableID}
  ${lib.concatMapStringsSep "\n" (x: let
    family = x.name;
    ipvX = x.value;
    X = builtins.fromJSON (builtins.substring (builtins.stringLength family - 1) 1 family);

    _birdTable = lib.replaceStrings ["%"] [(builtins.toString X)] (if birdTable != null then birdTable else "t%_${name}");
  in ''
    ${optionalString (ipvX != {} && ipvX.enable) ''
    ${lib.optionalString (birdTable == null) "${family} table ${_birdTable};"}
    protocol kernel KERNEL${toString X}_${toString name} {
      ${optionalString enable "# "}disabled;
      kernel table ${builtins.toString tableID};

      ${family} {
        table ${_birdTable};

      ${optionalString (ipvX.bgpImports == null || (ipvX.bgpImports != "" && ipvX.bgpImports.allowed != [])) (
        indentedLines 2 (mkFilter "import" "k${builtins.toString X}_${name}" ipvX.bgpImports)
      )}
      ${optionalString (ipvX.bgpExports == null || (ipvX.bgpExports != "" && ipvX.bgpExports.allowed != [])) (
        indentedLines 2 (mkFilter "export" "k${builtins.toString X}" ipvX.bgpExports)
      )}
      };
    }
    ''}
  '') (lib.attrsToList { inherit ipv4 ipv6; })}
''
