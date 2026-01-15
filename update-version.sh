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

cd "$PRGNAM"

source "$PRGNAM.SlackBuild"
sed -i "s|${VERSION/\./\\.}|$NEWVER|g" "$PRGNAM.SlackBuild"
unset -v VERSION
source "$PRGNAM.SlackBuild"

for URL in $([[ "$DOWNLOAD" != "UNSUPPORTED" ]] && echo "$DOWNLOAD" || echo "") \
           $([[ -n "$DOWNLOAD_x86" && "$DOWNLOAD_x86" != "UNSUPPORTED" ]] && echo "$DOWNLOAD_x86" || echo "")
do
  if [ ! -f "$(basename "$URL")" ]; then
    wget --tries=inf --retry-on-http-error=503 "$URL" || true
  fi
done

if [[ "$DOWNLOAD" != "UNSUPPORTED" ]]; then
  for TARBALL in $(basename -a $DOWNLOAD); do
    CHECKSUMS="$CHECKSUMS$(sha256sum "$TARBALL" | cut -d' ' -f1) "
  done
  CHECKSUMS="$(echo "${CHECKSUMS% }" | tr ' ' '\\n' | awk '{if(NR>1) printf "\\n%12s%s", "", $0; else printf "%s", $0}')"
  perl -0777 -pi -e 's|SHA256SUM="[0-9a-f\s\\]*"|SHA256SUM="'"$CHECKSUMS"'"|' "$PRGNAM.SlackBuild"
fi
if [[ -n "$DOWNLOAD_x86" && "$DOWNLOAD_x86" != "UNSUPPORTED" ]]; then
  for TARBALL in $(basename -a $DOWNLOAD_x86); do
    CHECKSUMS32="$CHECKSUMS32$(sha256sum "$TARBALL" | cut -d' ' -f1) "
  done
  CHECKSUMS32="$(echo "${CHECKSUMS32% }" | tr ' ' '\\n' | awk '{if(NR>1) printf "\\n%15s%s", "", $0; else printf "%s", $0}')"
  perl -0777 -pi -e 's|SHA256SUM_x86="[0-9a-f\s\\]*"|SHA256SUM_x86="'"$CHECKSUMS32"'"|' "$PRGNAM.SlackBuild"
fi

if [[ -z "$NOBUILD" ]]; then
  time fakeroot "$CWD/sb" "$PRGNAM.SlackBuild"
fi

cd "$CWD"
