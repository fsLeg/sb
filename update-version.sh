#!/bin/bash

# Update the version of SlackBuilds. Useful for incremental updates.
# Intended to be run from the root of the repo.
# It updates the version and SHA256 checksums in the .SlackBuild file.

set -e
shopt -u sourcepath

if [[ "${#@}" -ne 2 ]]; then
  echo "Usage: $0 PRGNAM NEWVER"
  exit 1
fi

PRGNAM="${1%/}"
NEWVER="$2"
CWD="$(pwd)"

if [[ ! -d "$PRGNAM" ]]; then
  echo "Directory \"$PRGNAM\" doesn't exist."
  exit 1
fi

if [[ "${ARCH:=$(uname -m)}" == "x86_64" ]]; then
  DEBARCH="amd64"
  PLATFORM="x64"
  BITS="64"
fi

cd "$PRGNAM"

# get old values
source "$PRGNAM.SlackBuild"

# version update hooks
case "$PRGNAM" in
  stable-diffusion.cpp)
    IFS="-" read -r _ REV NEWHASH <<< "$NEWVER"
    sed -i "s|^VERSION=\"$VERSION\"$|VERSION=\"$REV\"|
            s|^HASH=\"$HASH\"$|HASH=\"$NEWHASH\"|" \
        "$PRGNAM.SlackBuild"
    unset HASH REV NEWHASH
    ;;
  element-desktop)
    # this should probably be done on a tarball instead, but this way
    # there's no need to juggle the URLs and possibly re-read the
    # SlackBuild the third time
    NEWSESH="$(curl -fsSL "https://raw.githubusercontent.com/element-hq/element-web/refs/tags/v$NEWVER/apps/desktop/package.json" | node -p 'JSON.parse(require("fs").readFileSync(0,"utf8")).dependencies["@matrix-org/seshat"].replace(/[^0-9.]/g, "")')"
    sed -i "s|^VERSION=\"$VERSION\"$|VERSION=\"$NEWVER\"|
            s|^SESHVER=\"$SESHVER\"$|SESHVER=\"$NEWSESH\"|" \
        "$PRGNAM.SlackBuild"
    unset SESHVER NEWSESH
    ;;
  *)
    sed -i "s|${VERSION/\./\\.}|$NEWVER|g" "$PRGNAM.SlackBuild"
    ;;
esac
unset -v VERSION DOWNLOAD

# reset build number back to 1
sed -i 's|^BUILD="\${BUILD:-[0-9]\{1,\}}"$|BUILD="${BUILD:-1}"|' "$PRGNAM.SlackBuild"

# get new values
source "$PRGNAM.SlackBuild"

for URL in $DOWNLOAD; do
  if [[ ! "$URL" =~ ^git\+ ]]; then
    if [[ -f "$(basename "$URL")" ]]; then
      rm -fv "$(basename "$URL")"
    fi
    wget --tries=inf --retry-on-http-error=503 "$URL" || true
  fi
done

for ITEM in $DOWNLOAD; do
  if [[ "$ITEM" =~ ^git\+ ]]; then
    CHECKSUMS+="- "
  else
    CHECKSUMS+="$(sha256sum "$(basename $ITEM)" | cut -d' ' -f1) "
  fi
done
CHECKSUMS="$(echo "${CHECKSUMS% }" | tr ' ' '\n' | awk '{if(NR>1) printf "\n%11s%s", "", $0; else printf "%s", $0}')"
perl -0777 -pi -e 's|SHA256SUM="[-0-9a-f\s\\]*"|SHA256SUM="'"$CHECKSUMS"'"|' "$PRGNAM.SlackBuild"

if [[ -z "$NOBUILD" ]]; then
  time nice -n 19 fakeroot "$CWD/sb" "$PRGNAM.SlackBuild"
fi

cd "$CWD"
