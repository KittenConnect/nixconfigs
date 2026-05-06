creation_rules:
if builtins.isAttrs creation_rules then
  if creation_rules ? creation_rules then
    creation_rules
  else
    {
      creation_rules = builtins.map (
        n:
        let
          v = creation_rules.${n};
        in
        { path_regex = n; } // v
      ) (builtins.attrNames creation_rules);
    }
else if builtins.isList creation_rules then
  { inherit creation_rules; }
else
  throw "Unknown format for secrets.nix"
