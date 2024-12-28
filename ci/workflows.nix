let
  inherit (builtins)
    attrValues
    mapAttrs
    attrNames
    concatStringsSep
    length
    elemAt
    ;
  flatten = list: builtins.foldl' (acc: v: acc ++ v) [ ] list;
  getPath = v: (builtins.filter builtins.isString (builtins.split "\\." v));
  getValue =
    v: if nixActions.attrSuffix != "" then attrByPath (getPath nixActions.attrSuffix) v else v;
  attrByPath =
    attrPath: v:
    let

      default = (abort ("cannot find attribute `" + concatStringsSep "." attrPath + "'"));

      lenAttrPath = length attrPath;
      attrByPath' =
        n: s:
        (
          if n == lenAttrPath then
            s
          else
            (
              let
                attr = elemAt attrPath n;
              in
              if s ? ${attr} then attrByPath' (n + 1) s.${attr} else default
            )
        );
    in
    attrByPath' 0 v;

  workflows =
    let
      evaluated = (import nixActions.ciFile);
    in
    if nixActions.attrPrefix != "" then
      attrByPath (getPath nixActions.attrPrefix) evaluated
    else
      evaluated;

  nixActions = {
    githubPlatforms = {
      "x86_64-linux" = "ubuntu-22.04";
      "x86_64-darwin" = "macos-13";
      "aarch64-darwin" = "macos-14";
    };

    fileName = "colmena-anywhere.nix";
    ciFile = (./. + "/${nixActions.fileName}");

    attrPrefix = "";
    attrSuffix = "nixos-system";

    checks = {
      "x86_64-linux" = mapAttrs (n: v: getValue v) workflows;
    };
  };
in
{
  # inherit (nixActions) checks;

  include = flatten (
    attrValues (
      mapAttrs (
        system: pkgs:
        builtins.map (attr: {
          name = attr;
          inherit system;
          os =
            let
              os = nixActions.githubPlatforms.${system};
            in
            if builtins.typeOf os == "list" then os else [ os ];
          file = nixActions.ciFile;
          attr = (
            if nixActions.attrPrefix != "" then
              if nixActions.attrSuffix != "" then
                "${nixActions.attrPrefix}.\"${attr}\".${nixActions.attrSuffix}"
              else
                "${nixActions.attrPrefix}.\"${attr}\""
            else if nixActions.attrSuffix != "" then
              "\"${attr}\".${nixActions.attrSuffix}"
            else
              "\"${attr}\""
          );
        }) (attrNames pkgs)
      ) nixActions.checks
    )
  );
}