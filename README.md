# Introduction

sb is an alternative approach to Slackware's SlackBuilds.

It was inspired by CRUX's Pkgbuild and Arch's PKGBUILD. The main idea is to offload repeating code from SlackBuilds.org's SlackBuilds to a single place, in this case a master script called `sb`, thus making SlackBuilds more readable and easier to write. Also, more dependency information is provided in the metadata for possible future tools to use. The resulting executed code is pretty much the same as an SBo's SlackBuild, not counting a couple of quality of life improvements, namely automatic downloading of tarballs and their checksum checking.

The main principles that differ from the de facto standard set by SBo:
- `fakeroot` should be used instead of actual root.
- online builds are OK, so no need to vendor sources or put hundreds of links inside $DOWNLOAD to vendor later.
- everything should be installed under /usr/local to keep the base system clean.
- x86_64 is the primary target architecture instead of i586.
- SHA256 is used instead of MD5 for checksums.

The aforementioned differences are only in place in this repo. Nothing prevents users to use `sb` to build Slackware packages using SBo rules with minimal editing.

# SlackBuild format

A template for writing SlackBuilds to be used with `sb` tool can be sound in **template.SlackBuild** file in the root of the repo. It should have enough comments for understanding what is expected. The more detailed rundown is below. Knowledge how to write SlackBuilds for SBo is required.

All metadata variables must have their values enclosed in quotes. No executable code must be present outside of funtions as SlackBuilds are sourced by `sb`.

## Required metadata

- PRGNAM - program name.
- VERSION - program version.
- BUILD - package build number.
- DOWNLOAD - must be set to URL(s) or "UNSUPPORTED" if the program doesn't support x86_64 platform.
- SHA256SUM - only required if $DOWNLOAD is _not_ set to "UNSUPPORTED", can be omitted otherwise.

## Optional metadata

The following metadata can be omitted if empty.

- DESCRIPTION - brief description of the program, like the part in parentheses in slack-desc file.
- HOMEPAGE - URL of the program's homepage.
- DOWNLOAD_x86 - set to URL if there's a special tarball for i586 architecture; set to "UNSUPPORTED" if i586 architecture is explicitly not supported by the program.
- SHA256_x86 - required if $DOWNLOAD_x86 is set to URL.
- REQUIRED - list of runtime dependencies, separate with spaces.
- BUILD_REQUIRED - list of build-time dependencies. These are not required to actually run the program in question.
- OPTIONAL - list of optional packages, either autodetected at build time or enabled through environment variables.
- CONFLICTS - list of packages this package will conflict with, i. e. due to installing files to the same path.

## Functions

- unpack() - same as prepare() from Arch's PKGBUILD. The end result must be a directory named $PRGNAM-$VERSION with ready to build sources inside. If there are any patched or other preparations needed, apply them here.

- build() - same as build() from CRUX's Pkgbuild. Here you build the program and put files into $PKG the same way you would do in a regular SlackBuild. `sb` will take care of putting slack-desc, doinst.sh and douninst.sh files in a proper place and creating the actual package. If you need to modify slack-desk/doinst.sh/douninst.sh files before packaging them, you can do that and put them into $PKG/install directory, `sb` won't overwrite them.

# sb provided variables and funcions

The `sb` tool provides various variables and a few functions in hopes of being useful when writing a SlackBuild for it.

## Variables

- $TMP, $CWD, $PKG, $ARCH, $SLKCFLAGS, $LIBDIRSUFFIX - same as on SBo
- $DEBARCH - architecture the way Debian names it (i386, amd64, armhf, arm64)
- $PLATFORM - platform identifier (ia32, x64, arm, arm64)
- $BITS - how many bits architecture has (32, 64)
- $_PREFIX - /usr/local

CFLAGS and the like are already exported, so you don't need to set
them, unless you want to change them. For full list of variables see
the source of sb.

## Functions

TODO
