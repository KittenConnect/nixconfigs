let
  inherit (builtins)
    attrValues
    mapAttrs
    attrNames
    concatStringsSep
    length
    elem
    elemAt
    foldl'
    ;

  filterAttrs =
    f: as:
    builtins.listToAttrs (
      map (name: {
        inherit name;
        value = as.${name};
      }) (builtins.filter (n: f n (as.${n})) (builtins.attrNames as))
    );

  onlyJobs = # nullOr
    null; # [ "" ];

  withoutJobs = [ "laptaupe" "NIXP" ]; # nullOr

  onlyWanted =
    jobs:
    let
      withoutUnwanted = filterAttrs (n: v: !builtins.elem n withoutJobs);
      getJobs = if withoutJobs == null then jobs else withoutUnwanted jobs;
    in
    if onlyJobs == null then getJobs else filterAttrs (n: v: builtins.elem n onlyJobs) getJobs;

  flatten = list: builtins.foldl' (acc: v: acc ++ v) [ ] list;
  unique = foldl' (acc: e: if elem e acc then acc else acc ++ [ e ]) [ ];
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

    jobs = {
      "x86_64-linux" = (mapAttrs (n: v: getValue v) (onlyWanted workflows));
    };
  };
in
{
  # inherit (nixActions) jobs;

  include = # unique (map (n: builtins.toString workflows.${n}.nix-package) (attrNames workflows)) ++
    flatten (
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
        ) nixActions.jobs
      )
    );
}
