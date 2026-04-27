creation_rules: if builtins.isList creation_rules then { inherit creation_rules; } else throw "Unknown format for secrets.nix"
