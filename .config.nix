{
  allowUnfreePredicate =
    let
      unfreePackages = import ./.unfree.nix;
    in
    pkg:
    builtins.elem pkg.pname unfreePackages
    || (pkg ? name && builtins.elem (builtins.parseDrvName pkg.name).name unfreePackages);
}
