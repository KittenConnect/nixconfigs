let
  inherit ((import ../. {}).inputs) pkgs lib;
  rulesExpr = ''
  '';
in pkgs.writeShellScriptBin "sops" ''
  #!/usr/bin/env bash

  set -euo pipefail

  set -x

  NIX_RULES="$(readlink -f ./.sops.nix)"
  SOPS_RULES="/tmp/sopsnix_$(pwd | sha1sum | cut -d' ' -f1)"

  nix eval --json -v -f $NIX_RULES --apply ${lib.escapeShellArg (builtins.readFile ./sops.expr.nix)} | yq -r . > "$SOPS_RULES.$$"
  if ! diff --color -uN $SOPS_RULES $SOPS_RULES.$$; then
    mv $SOPS_RULES.$$ $SOPS_RULES
  else
    rm $SOPS_RULES.$$
  fi

  SOPS_CONFIG="$SOPS_RULES" exec sops "$@"
''
