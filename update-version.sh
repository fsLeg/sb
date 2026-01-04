#!/bin/sh

# Update the version of SlackBuilds. Useful for incremental updates.
# Intended to be run from the root of the repo.
# It updates the version and SHA256 checksums in the .SlackBuild file.

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 PRGNAM NEWVER"
  exit 1
fi

PRGNAM="${1%/}"
NEWVER="$2"
CWD="$(pwd)"

cd "$PRGNAM"

. "./$PRGNAM.SlackBuild"
sed -i "s|${VERSION/\./\\.}|$NEWVER|g" "$PRGNAM.SlackBuild"
unset -v VERSION
. "./$PRGNAM.SlackBuild"

for URL in $(test "$DOWNLOAD" != "UNSUPPORTED" && echo "$DOWNLOAD" || echo "") \
           $(test -n "$DOWNLOAD_x86" && echo "$DOWNLOAD_x86" || echo "")
do
  if [ ! -f "$(basename "$URL")" ]; then
    wget --tries=inf --retry-on-http-error=503 "$URL" || true
  fi
done

if [ "$DOWNLOAD" != "UNSUPPORTED" ]; then
  for TARBALL in $(basename -a $DOWNLOAD); do
    CHECKSUMS="$CHECKSUMS$(sha256sum "$TARBALL" | cut -d' ' -f1) "
  done
  perl -0777 -pi -e 's|SHA256SUM="[0-9a-f\s\\]*"|SHA256SUM="'"${CHECKSUMS% }"'"|' "$PRGNAM.SlackBuild"
fi
if [ -n "$DOWNLOAD_x86" ]; then
  for TARBALL in $(basename -a $DOWNLOAD_x86); do
    CHECKSUMS32="$CHECKSUMS32$(sha256sum "$TARBALL" | cut -d' ' -f1) "
  done
  perl -0777 -pi -e 's|SHA256SUM_x86="[0-9a-f\s\\]*"|SHA256SUM_x86="'"${CHECKSUMS32% }"'"|' "$PRGNAM.SlackBuild"
fi

if [ -z "$NOBUILD" ]; then
  time fakeroot $CWD/sb $PRGNAM.SlackBuild
fi

cd "$CWD"
