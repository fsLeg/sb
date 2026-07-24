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

source "$PRGNAM.SlackBuild"
sed -i "s|${VERSION/\./\\.}|$NEWVER|g" "$PRGNAM.SlackBuild"
unset -v VERSION
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
