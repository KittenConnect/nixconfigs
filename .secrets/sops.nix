let
  inherit ((import ../. { }).inputs) pkgs lib;
  exprRules = builtins.readFile ./sops.expr.nix;
in
pkgs.writeShellScriptBin "sopsnix" ''
  #!/usr/bin/env bash

  set -euo pipefail

  set -x

  REPO="$(${pkgs.git}/bin/git rev-parse --show-toplevel)"

  NIX_RULES="$REPO/.sops.nix"
  SOPS_RULES="$REPO/.sops.yaml"

  if nix eval -v --show-trace --json -v -f $NIX_RULES --apply ${lib.escapeShellArg exprRules} | ${pkgs.yq}/bin/yq -r . > "$SOPS_RULES.$$"; then
    if ! diff --color -uN $SOPS_RULES $SOPS_RULES.$$; then
      mv $SOPS_RULES.$$ $SOPS_RULES
    else
      rm $SOPS_RULES.$$
    fi

    SOPS_CONFIG="$SOPS_RULES" exec sops "$@"
  else
    rm $SOPS_RULES.$$
  fi
''
