# adapted from https://github.com/nix-community/home-manager/blob/release-25.11/modules/lib/file-type.nix
# TODO: adapt
{
  lib,
  pkgs,
  homeDirectory ? "/etc",
  ...
}: let
  inherit
    (lib)
    hasPrefix
    hm
    literalExpression
    mkDefault
    mkIf
    mkOption
    removePrefix
    types
    ;
in {
  # Constructs a type suitable for a `environment.etc` like option. The
  # target path may be either absolute or relative, in which case it
  # is relative the `basePath` argument (which itself must be an
  # absolute path).
  #

  # environment.etc.<name>.enable
  # environment.etc.<name>.target
  # environment.etc.<name>.text
  # environment.etc.<name>.source
  # environment.etc.<name>.gid
  # environment.etc.<name>.group
  # environment.etc.<name>.mode -> executable
  # environment.etc.<name>.uid
  # environment.etc.<name>.user

  # Arguments
  #   - opt            the name of the option, for self-references
  #   - basePathDesc   docbook compatible description of the base path
  #   - basePath       the file base path
  fileType = opt: basePath: _options:
    types.attrsOf (
      types.submodule (
        {
          name,
          config,
          options,
          ...
        }: {
          options =
            (lib.optionalAttrs (_options != null) _options)
            // {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = ''
                  Whether this /etc file should be generated.  This
                  option allows specific /etc files to be disabled.
                '';
              };

              target = mkOption {
                type = types.str;
                apply = p: let
                  absPath =
                    if hasPrefix "/" p
                    then p
                    else "${basePath}/${p}";
                in
                  removePrefix (homeDirectory + "/") absPath;
                defaultText = literalExpression "name";
                description = ''
                  Path to target file relative to ${basePath}.
                '';
              };

              text = lib.mkOption {
                default = null;
                type = lib.types.nullOr lib.types.lines;
                description = "Text of the file.";
              };

              source = lib.mkOption {
                type = lib.types.path;
                description = "Path of the source file.";
              };

              mode = lib.mkOption {
                type = lib.types.str;
                default = "symlink";
                example = "0600";
                description = ''
                  If set to something else than `symlink`,
                  the file is copied instead of symlinked, with the given
                  file mode.
                '';
              };

              uid = lib.mkOption {
                default = 0;
                type = lib.types.int;
                description = ''
                  UID of created file. Only takes effect when the file is
                  copied (that is, the mode is not 'symlink').
                '';
              };

              gid = lib.mkOption {
                default = 0;
                type = lib.types.int;
                description = ''
                  GID of created file. Only takes effect when the file is
                  copied (that is, the mode is not 'symlink').
                '';
              };

              user = lib.mkOption {
                default = "+${toString config.uid}";
                type = lib.types.str;
                description = ''
                  User name of file owner.

                  Only takes effect when the file is copied (that is, the
                  mode is not `symlink`).

                  When `services.userborn.enable`, this option has no effect.
                  You have to assign a `uid` instead. Otherwise this option
                  takes precedence over `uid`.
                '';
              };

              group = lib.mkOption {
                default = "+${toString config.gid}";
                type = lib.types.str;
                description = ''
                  Group name of file owner.

                  Only takes effect when the file is copied (that is, the
                  mode is not `symlink`).

                  When `services.userborn.enable`, this option has no effect.
                  You have to assign a `gid` instead. Otherwise this option
                  takes precedence over `gid`.
                '';
              };
            };

          config = {
            target = mkDefault name;
            source = lib.mkIf (config.text != null) (
              let
                name' = "etc-bird-" + lib.replaceStrings ["/"] ["-"] name;
              in
                if lib.versionOlder lib.version "25.05"
                then lib.mkOptionDefault (pkgs.writeText name' config.text)
                else lib.mkDerivedConfig options.text (pkgs.writeText name')
              #                   lib.mkForce options.text (pkgs.writeText name')
            );
          };
        }
      )
    );
}
