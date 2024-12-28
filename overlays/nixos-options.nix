(final: prev: {
  nixos-option =
    let
      prefix = ''(import /etc/nixos/ci/hive.nix).nodes.\$(hostname)'';
    in
    prev.runCommandNoCC "nixos-option" { buildInputs = [ prev.makeWrapper ]; } ''
      makeWrapper ${prev.nixos-option}/bin/nixos-option $out/bin/nixos-option \
        --add-flags --config_expr \
        --add-flags "\"${prefix}.config\"" \
        --add-flags --options_expr \
        --add-flags "\"${prefix}.options\""
    '';
})
