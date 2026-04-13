PROFILE=/nix/var/nix/profiles/system
ACTUAL="$(readlink -f /run/current-system)"

# GH_ACCESS_TOKEN=""
GH_ACCESS_FILE=~/.cache/nix/sysupgrade-token.json
GH_CLIENT_ID=Ov23liro3mdNvilxzCM5 # TODO: move to nix options
GH_RETRY_INTERVAL=1
GH_OWNER=kittenconnect
GH_REPO=nixconfigs

HTTP_MIRROR=https://$GH_OWNER.github.io/$GH_REPO
NIX_CACHE=$HTTP_MIRROR/cache
NIX_PUBKEY=""

NIX_COPY_OPTIONS=()

if [[ -n "${GH_ARTIFACT:-}" ]]; then
  accessToken=${GH_ACCESS_TOKEN:-}
  [[ -n "$accessToken" ]] || accessToken=$(jq -r '.access_token // ""' < $GH_ACCESS_FILE || true)

  if [[ -n "$accessToken" ]] && response=$(curl -fsSL https://api.github.com/user \
  -H "Accept: application/json" \
  -H "Authorization: Bearer ${accessToken}"); then
    jq -r '"Logged in as \(.name) [\(.url)]"' <<< "$response" >&2;
  else
    # if [[ ! -v GH_CLIENT_ID ]]; then echo "GH_CLIENT_ID is unset - please provide a GH_ACCESS_TOKEN" >&2

    response=$(curl -fsSL -X POST https://github.com/login/device/code \
      -H "Accept: application/json" \
      -d "client_id=$GH_CLIENT_ID" \
      -d "scope=repo")

    expires=$(date -d "now + $(jq -r .expires_in <<< "$response")sec" +%s)
    deviceCode=$(jq -r .device_code <<< "$response")
    userCode=$(jq -r .user_code <<< "$response")
    verifURI=$(jq -r .verification_uri <<< "$response")
    interval=$(jq -r .interval <<< "$response")
    if [[ $GH_RETRY_INTERVAL -gt $interval ]]; then interval=$GH_RETRY_INTERVAL; fi

    echo "please use $userCode on $verifURI then wait for authentication to succeed" >&2

    while [[ $(date +%s) -le $expires ]]; do
    response=$(curl -fsSL -X POST https://github.com/login/oauth/access_token \
        -H "Accept: application/json" \
        -d "client_id=$GH_CLIENT_ID" \
        -d "device_code=$deviceCode" \
        -d "grant_type=urn:ietf:params:oauth:grant-type:device_code")

    accessToken=$(jq -r '.access_token // ""' <<< "$response")
    if [[ -n "$accessToken" ]]; then echo "$response" > $GH_ACCESS_FILE; break; fi

    [[ "$(jq -r .error <<< "$response")" == "authorization_pending" ]] || jq -r . <<< "$response" # TODO: err handling

    sleep "$interval"
    done
  fi

  if response=$(curl -fsSL "https://api.github.com/repos/$GH_OWNER/$GH_REPO/actions/artifacts/$GH_ARTIFACT" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer ${accessToken}"); then
    jq -r . <<< "$response" >&2
    cache=/var/tmp/sysupgrade/$GH_ARTIFACT
    mkdir -vp "$cache"
    if [[ -d $cache/nar ]] || [[ -f "${cache}.zip" ]] \
      || curl -fSL -H "Authorization: Bearer ${accessToken}" --continue-at - -o "${cache}.zip" "$(jq -r .archive_download_url <<< "$response")"; then
        [[ -d $cache/nar ]] || unzip "${cache}.zip" -d "$cache"
      TOPLEVEL=$(cat "$cache/toplevel")
      NIX_CACHE="file://$cache"
      if [[ -f "$cache/sign.key" ]]; then NIX_PUBKEY=$(cat "$cache/sign.key"); else NIX_PUBKEY=insecure; fi
    else
      rm -rvf "/var/tmp/sysupgrade/$GH_ARTIFACT"
    fi
  fi
else
  TOPLEVEL=$(curl -fsSL $HTTP_MIRROR/index.txt | awk '$1 == "'"$(hostname)"'" { print $NF }')
  if [[ -z "$TOPLEVEL" ]]; then
          exit 1
  fi

  NIX_PUBKEY="$(curl -fsSL $HTTP_MIRROR/cache/sign.key)"
fi

if [[ "$TOPLEVEL" == "$ACTUAL" ]]; then
  exit 0
fi

if [[ -n "$NIX_PUBKEY" ]] && [[ "$NIX_PUBKEY" == "insecure" ]]; then
  NIX_COPY_OPTIONS+=(--no-check-sigs)
elif [[ -n "$NIX_PUBKEY" ]]; then
  NIX_COPY_OPTIONS+=(--option extra-trusted-public-keys "$NIX_PUBKEY")
fi

nix copy "${NIX_COPY_OPTIONS[@]}" --from "$NIX_CACHE" "$TOPLEVEL"

if "$TOPLEVEL/bin/switch-to-configuration" dry-activate; then
  nix-env --profile "$PROFILE" --set "$TOPLEVEL" && "$TOPLEVEL/bin/switch-to-configuration" "${1:-switch}"
fi
