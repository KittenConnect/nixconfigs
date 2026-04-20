final: prev: {
  nixos-option = let
    prefix = ''(import /etc/nixos/ci/hive.nix).nodes.\$(hostname)'';
  in
    prev.nixos-option.overrideAttrs (
      finalAttrs: prevAttrs: {
        buildInputs = (prev.buildInputs or []) ++ [prev.makeWrapper];

        postFixup = ''
          wrapProgram $out/bin/nixos-option \
          --add-flags --config_expr \
          --add-flags "\"${prefix}.config\"" \
          --add-flags --options_expr \
          --add-flags "\"${prefix}.options\""
        '';
      }
    );
}
