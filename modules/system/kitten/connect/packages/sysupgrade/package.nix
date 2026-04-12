{writeShellApplication}: writeShellApplication {
    name = "kitten-sysupgrade";

    runtimeInputs = [];

    text = ''
        REPO=https://kittenconnect.github.io/nixconfigs
        PROFILE=/nix/var/nix/profiles/system
        ACTUAL="$(readlink -f /run/current-system)"
        TOPLEVEL=$(curl -fsSL $REPO/index.txt | awk '$1 == "'"$(hostname)"'" { print $NF }')
        if [[ -z "$TOPLEVEL" ]]; then
                exit 1
        fi

        if [[ "$TOPLEVEL" == "$ACTUAL" ]]; then
              exit 0
        fi

        nix copy --option extra-trusted-public-keys "$(curl -fsSL $REPO/cache/sign.key)" --from "$REPO/cache" "$TOPLEVEL"

        if "$TOPLEVEL/bin/switch-to-configuration" dry-activate; then
            nix-env --profile "$PROFILE" --set "$TOPLEVEL" && "$TOPLEVEL/bin/switch-to-configuration" "''${1:-test}"
        fi
    '';
}
