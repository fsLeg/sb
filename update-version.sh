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

if [[ -z "$ARCH" ]]; then
  case "$(uname -m)" in
    i?86) ARCH="i586" ;;
    arm*) ARCH="arm" ;;
       *) ARCH="$(uname -m)" ;;
  esac
fi

if [[ "$ARCH" == i?86 ]]; then
  DEBARCH="i386"
  PLATFORM="ia32"
  BITS="32"
elif [[ "$ARCH" == "arm" ]]; then
  DEBARCH="armhf"
  PLATFORM="arm"
  BITS="32"
elif [[ "$ARCH" == "x86_64" ]]; then
  DEBARCH="amd64"
  PLATFORM="x64"
  BITS="64"
elif [[ "$ARCH" == "aarch64" ]]; then
  DEBARCH="arm64"
  PLATFORM="arm64"
  BITS="64"
fi

cd "$PRGNAM"

source "$PRGNAM.SlackBuild"
sed -i "s|${VERSION/\./\\.}|$NEWVER|g" "$PRGNAM.SlackBuild"
unset -v VERSION
source "$PRGNAM.SlackBuild"

for URL in $([[ "$DOWNLOAD" != "UNSUPPORTED" ]] && echo "$DOWNLOAD" || echo "") \
           $([[ -n "$DOWNLOAD_x86" && "$DOWNLOAD_x86" != "UNSUPPORTED" ]] && echo "$DOWNLOAD_x86" || echo "")
do
  if [[ ! "$URL" =~ ^git\+ && ! -f "$(basename "$URL")" ]]; then
    wget --tries=inf --retry-on-http-error=503 "$URL" || true
  fi
done

if [[ "$DOWNLOAD" != "UNSUPPORTED" ]]; then
  for ITEM in $DOWNLOAD; do
    if [[ "$ITEM" =~ ^git\+ ]]; then
      CHECKSUMS+="- "
    else
      CHECKSUMS+="$(sha256sum "$(basename $ITEM)" | cut -d' ' -f1) "
    fi
  done
  CHECKSUMS="$(echo "${CHECKSUMS% }" | tr ' ' '\n' | awk '{if(NR>1) printf " \\\\\\\n%11s%s", "", $0; else printf "%s", $0}')"
  perl -0777 -pi -e 's|SHA256SUM="[-0-9a-f\s\\]*"|SHA256SUM="'"$CHECKSUMS"'"|' "$PRGNAM.SlackBuild"
fi
if [[ -n "$DOWNLOAD_x86" && "$DOWNLOAD_x86" != "UNSUPPORTED" ]]; then
  for ITEM in $DOWNLOAD_x86; do
    if [[ "$ITEM" =~ ^git\+ ]]; then
      CHECKSUMS32+="- "
    else
      CHECKSUMS32+="$(sha256sum "$TARBALL" | cut -d' ' -f1) "
    fi
  done
  CHECKSUMS32="$(echo "${CHECKSUMS32% }" | tr ' ' '\n' | awk '{if(NR>1) printf " \\\\\\\n%15s%s", "", $0; else printf "%s", $0}')"
  perl -0777 -pi -e 's|SHA256SUM_x86="[0-9a-f\s\\]*"|SHA256SUM_x86="'"$CHECKSUMS32"'"|' "$PRGNAM.SlackBuild"
fi

if [[ -z "$NOBUILD" ]]; then
  time fakeroot "$CWD/sb" "$PRGNAM.SlackBuild"
fi

cd "$CWD"
