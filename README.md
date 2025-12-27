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

To use `sb` put it somewhere on your PATH and simply execute

    sb path/to/appname.SlackBuild

This is similar to SBo's SlackBuilds that are called as `bash appname.SlackBuild`, except `sb` retrieves a SlackBuild's directory using `dirname`, so you don't have to `cd` into a SlackBuild's directory first. Obviously, it only works with this repo's SlackBuilds which are specifically made to be used with `sb`.

# SlackBuild format

A template for writing SlackBuilds to be used with `sb` tool can be sound in **template.SlackBuild** file in the root of the repo. It should have enough comments for understanding what is expected. The more detailed rundown is below. Knowledge how to write SlackBuilds for SBo is required.

All metadata variables must have their values enclosed in quotes. No executable code must be present outside of funtions as SlackBuilds are sourced by `sb`. Additional variables (like behaviour variables) can be present outside of functions since they aren't an executable code.

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
- REQUIRED - list of runtime dependencies, separate with spaces. Alternative dependencies can be specified using `|` symbol, i. e. REQUIRES="appname1|altappname1 appname2".
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

## Behaviour variables

sb also uses some variables that fine-tune what it does.

### Environment variables

These must be present in the environment when invoking `sb`.

- $USE_REAL_ROOT - set to anything other than "N" (i. e. USE_REAL_ROOT=y) to supress a warning about not using `fakeroot` when running `sb` as root.
- $PRINT_PACKAGE_NAME - same as on SBo, set to anything to only print the name of the package that would be built and immediately exit.

### Script variables

These must be set in a SlackBuild outside of functions, preferrably right after metadata variables.

- $SKIP_PERMS - set to anything (i. e. SKIP_PERMS=1) to skip permission reset after unpacking. Useful when a tarball has some funky files, like a looping symlink in a test directory, that make the script fail at this step.
- $SKIP_STRIP - set to anything (i. e. SKIP_STRIP=true) to skip stripping binaries and libraries in $PKG after building is done. Useful when repackaging static binaries that stop working after stripping process.
- $PKGVER - this variable overrides $VERSION when creating the package. Useful when the package version should differ from the sources version, i. e. for kernel modules.

## Functions

- reset_permissions() - recursively set the owner in a current directory to root:root, chmod all executable files and directories to 755 and non-executable files to 644.

# Rationale

Why did I write `sb` in the first place? Reasons in no particular order:

1. SlackBuilds can be overwhelming and there's a lot of repeating code from SlackBuild to SlackBuild. Putting such repeating code into a master script should increase a SlackBuild's readability and make it easier to write one.
2. SlackBuilds are canonically run as root. But it is only needed for makepkg so `tar` saves correct permissions when creating the package. For that `fakeroot` is sufficient. However, with modern build systems more and more often requiring Internet access, building as root becomes increasingly dangerous. So the recommended way is using `fakeroot`, however, users can still use actual root if they so desire. For automation and less annoyance they can set the USE_REAL_ROOT environment variable as outlined above. This also implies that Internet access is expected. That's just the world we live in.
3. Insufficient dependency information in SBo's .info files. There should be separate fields for build dependencies that aren't required for a package to run, conflicts (i. e. element-desktop can't be installed alongside element-desktop-bin) and alternatives (i.e. yarn can use either nodejs or nodejs24-bin). While `sb` itself doesn't use that information, it can be used by external tools that then will be able to provide better dependency resolution.
4. FreeBSD separates system packages from user-installed ones by making the user install all their packages into /usr/local. I think this is a sound idea, especially since Slackware is positioned as a complete system with batteries included. Also, separating third-party packages like that can potentially open possibility to safely install upgraded versions of packages that are already included in Slackware, i. e. python 3.12 when Slackware only has python 3.9.
5. There's no real reason to use SHA256 checksum instead of MD5 (you can argue that a bad actor can craft a malicious tarball with a desired MD5 checksum, and while it's possible in theory, I'm yet so see anyone actually do this), but since it's an alternative approach, I thought, why not use what the cool kids use? And they seem to mostly use SHA256 nowadays.
6. SBo was made when Slackware64 didn't officially exist, so everything assumes 32 bit as the default architecture. This hasn't been the case for the past 10+ years, so instead of using DOWNLOAD for 32 bit and DOWNLOAD_X86_64 for 64 bit, I use DOWNLOAD for 64 bit and DOWNLOAD_x86 for 32 bit.
7. Slackware is the only distro I know that executes its build scripts directly. CRUX, Arch and Gentoo (most notable examples, but also pretty much every other distro) use a master script that parses Pkgbuild/PKGBUILD/ebuild to build the package. This keeps the build scripts focused on just building thus potentially increasing a repo's maintainability at the cost of the master script's complexity.

# Caveats

- Admittedly, using a master script is more restrictive than a regular SlackBuild. While in a SlackBuild you can change every step as you see fit, in `sb` I have to handle every edge case by increasing the code's complexity and decreasing its maintainability. SlackBuilds themselves do look nicer, though.
- Slackware wasn't designed with package separation in mind, so it's not possible to put every package into /usr/local prefix, things like plugins, extensions and perl/python/ruby libraries require you to put them into their direct dependency's prefix. So symlinks must be used in such cases as a crutch.
