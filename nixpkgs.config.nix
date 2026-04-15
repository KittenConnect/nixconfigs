{
  # allowUnfree = true;
  allowUnfreePredicate =
    let
      unfreePackages = [
        "vscode"
      ];
    in
    pkg:
    builtins.elem pkg.pname unfreePackages
    || (pkg ? name && builtins.elem (builtins.parseDrvName pkg.name).name unfreePackages);
}
