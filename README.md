# Introduction

sb is an alternative approach to Slackware's SlackBuilds.

It was inspired by CRUX's Pkgbuild and Arch's PKGBUILD. The main idea is to offload repeating code from SlackBuilds.org's SlackBuilds to a single place, in this case a master script called `sb`, thus making SlackBuilds more readable and easier to write. Also, more dependency information is provided in the metadata for possible future tools to use. The resulting executed code is pretty much the same as an SBo's SlackBuild, not counting a couple of quality of life improvements, namely automatic downloading of tarballs and their checksum checking.

The main principles that differ from the de facto standard set by SBo:
- `fakeroot` should be used instead of actual root.
- online builds are OK, so no need to vendor sources or put hundreds of links inside DOWNLOAD to vendor later.
- everything should be installed under /usr/local to keep the base system clean.
- x86_64 is the only target architecture, anything else is unsupported. You can still try running `sb` for those architectures if the source can be built for them using the same steps.
- SHA256 is used instead of MD5 for checksums.

The aforementioned differences are only in place in this repo. Nothing prevents users to use `sb` to build Slackware packages using SBo rules with minimal editing.

To use `sb` put it somewhere in your PATH and simply execute

    sb path/to/appname.SlackBuild

This is similar to SBo's SlackBuilds that are called as `bash appname.SlackBuild`, except `sb` retrieves a SlackBuild's directory using `dirname`, so you don't have to `cd` into a SlackBuild's directory first. Obviously, it only works with this repo's SlackBuilds which are specifically made to be used with `sb`.

# SlackBuild format

A template for writing SlackBuilds to be used with `sb` tool can be found in **template.SlackBuild** file in the root of the repo. It should have enough comments for understanding what is expected. The more detailed rundown is below. Knowledge how to write SlackBuilds for SBo is required.

All metadata variables must have their values enclosed in quotes. No executable code should be present outside of funtions as SlackBuilds are sourced by `sb`. Additional variables (like behaviour variables) can be present outside of functions since they aren't an executable code. You can unset or re-set variables from `sb` if you need.

## Required metadata

- PRGNAM - program name.
- VERSION - program version.
- BUILD - package build number.
- DOWNLOAD - must be set to URL(s). A URL can be prepended with "git+" if it is a git repository to be mirrored and suffixed with "#param=value&param2=value2" (i. e. `git+https://git.example.com/dev/project.git#branch=mistress`); currently, only "branch" URL parameter is supported, it sets a branch to mirror.
- SHA256SUM - a list of sha256 checksums separated with spaces or escaped newlines. Order must match URLs in DOWNLOAD. For URLs that are git repositories must be set to "-".

## Optional metadata

The following metadata can be omitted if empty.

- DESCRIPTION - brief description of the program, like the part in parentheses in slack-desc file.
- HOMEPAGE - URL of the program's homepage.
- REQUIRES - array of runtime dependencies. Alternative dependencies can be specified using the "|" symbol, i. e. `REQUIRES=("appname1|altappname1" appname2)`, and they must be quoted. Also used for slack-required. Feel free to adjust later in script to include autodetected or active optional dependencies.
- BUILD_REQUIRES - array of build-time dependencies. These are not required to actually run the program in question.
- OPTIONAL - array of optional packages, either autodetected at build time or enabled through environment variables.
- CONFLICTS - array of packages this package will conflict with, i. e. due to installing files to the same path. Also used for slack-conflicts.
- SUGGESTS - array of recommended packages to have with this one. Must not be runtime or build-time dependencies. Also used for slack-suggests.

## Functions

- unpack - same as prepare() from Arch's PKGBUILD. The end result must be a directory named $PRGNAM-$VERSION with ready to build sources inside. If there are any patches or other preparations needed, apply them here.
- build - same as build() from CRUX's Pkgbuild. Here you build the program and put files into $PKG the same way you would do in a regular SlackBuild. `sb` will take care of putting slack-desc, doinst.sh and douninst.sh files in a proper place and creating the actual package. If you need to modify slack-desc/doinst.sh/douninst.sh files before packaging them, you can do that and put them into $PKG/install directory, `sb` won't overwrite them.

# sb provided variables and funcions

The `sb` tool provides various variables and a few functions in hopes of being useful when writing a SlackBuild for it.

## Variables

- TMP, CWD, PKG, ARCH, SLKCFLAGS, LIBDIRSUFFIX - same as on SBo; TMP is /tmp/sb, can be changed through SB_TMP environment variable.
- DEBARCH - architecture the way Debian names it (i386, amd64, armhf, arm64)
- PLATFORM - platform identifier (ia32, x64, arm, arm64)
- BITS - how many bits architecture has (32, 64)
- _PREFIX - /usr/local, can be changed through SB_PREFIX environment variable.
- SYSCONFDIR - if $_PREFIX=/usr, then SYSCONFDIR=/etc, else SYSCONFDIR=$_PREFIX/etc
- LOCALSTATEDIR - if $_PREFIX=/usr, then SYSCONFDIR=/var, else SYSCONFDIR=$_PREFIX/var
- PYVER - major Python3 version (i. e. 3.9)
- SLACKVER - Slackware version (numerical or "current")
- UNTAR - `tar --no-same-owner -xvf`

CFLAGS and the like are already exported, so you don't need to set them, unless you want to change them. For full list of variables see the source of sb. CFLAGS and CXXFLAGS are set to use gold/mold as the linker in Slackware-stable and -current respectively.

## Behaviour variables

sb also uses some variables that fine-tune what it does.

### Environment variables

These are picked from the environment when invoking `sb`.

- SB_USE_REAL_ROOT - set to anything other than "N" (i. e. SB_USE_REAL_ROOT=Y) to supress a warning about not using `fakeroot` when running `sb` as root.
- SB_IGNORE_ARCH - set to anything other than "N" (i. e. SB_IGNORE_ARCH=y) to suppress a warning when building on unsupported architectures.
- SB_PREFIX - a prefix to use when creating a package, see _PREFIX above.
- SB_TMP - a directory to do the building in; see TMP above.
- SB_OUTPUT - a directory to put the resulting package in.
- PRINT_PACKAGE_NAME - same as on SBo, set to anything to only print the name of the package that would be built and immediately exit.

### Script variables

These must be set in a SlackBuild outside of functions, preferrably right after metadata variables.

- SKIP_PERMS - set to anything (i. e. SKIP_PERMS=1) to skip permission reset after unpacking. Useful when a tarball has some funky files, like a looping symlink in a test directory, that make the script fail at this step.
- SKIP_STRIP - set to anything (i. e. SKIP_STRIP=true) to skip stripping binaries and libraries in $PKG after building is done. Useful when repackaging static binaries that stop working after stripping process.
- PKGVER - this variable overrides $VERSION when creating the package. Useful when the package version should differ from the sources version, i. e. for kernel modules.

## Functions

- reset_permissions - recursively set the owner of a current or provided directory to root:root, chmod all executable files and directories to 755 and non-executable files to 644.
- compress_files - recursively gzip every file within a current or provided directory.
- check_gid - check if a group exists. Usage: `check_gid <group> <gid>`.
- check_uid - check if a user exists. Usage: `check_uid <user> <uid>`. Assumes UID=GID.
- get_submodules - recursively get git submodules using .gitmodules file. Takes a directory with .gitmodules file as an optional argument, works in a current directory otherwise. Skips directories with no .gitmodules file.

# Rationale

Why did I write `sb` in the first place? Reasons in no particular order:

1. SlackBuilds can be overwhelming and there's a lot of repeating code from SlackBuild to SlackBuild. Putting such repeating code into a master script should increase a SlackBuild's readability and make it easier to write one.
2. SlackBuilds are canonically run as root. But it is only needed for makepkg so `tar` saves correct permissions when creating the package. For that `fakeroot` is sufficient. However, with modern build systems more and more often requiring Internet access, building as root becomes increasingly dangerous. So the recommended way is using `fakeroot`, however, users can still use actual root if they so desire. For automation and less annoyance they can set the SB_USE_REAL_ROOT environment variable as outlined above. This also implies that Internet access is expected. That's just the world we live in.
3. Insufficient dependency information in SBo's .info files. There should be separate fields for build dependencies that aren't required for a package to run, conflicts (i. e. element-desktop can't be installed alongside element-desktop-bin) and alternatives (i.e. yarn can use either nodejs or nodejs24-bin). While `sb` itself doesn't use that information, it can be used by external tools that then will be able to provide better dependency resolution.
4. FreeBSD separates system packages from user-installed ones by making the user install all their packages into /usr/local. I think this is a sound idea, especially since Slackware is positioned as a complete system with batteries included. Also, separating third-party packages like that can potentially open possibility to safely install upgraded versions of packages that are already included in Slackware, i. e. python 3.12 when Slackware only has python 3.9.
5. There's no real reason to use SHA256 checksum instead of MD5 (you can argue that a bad actor can craft a malicious tarball with a desired MD5 checksum, and while it's possible in theory, I'm yet to see anyone actually do this), but since it's an alternative approach, I thought, why not use what the cool kids use? And they seem to mostly use SHA256 nowadays.
6. SBo was made when Slackware64 didn't officially exist, so everything assumes 32 bit as the default architecture. This hasn't been the case for the past 10+ years, so instead of using DOWNLOAD for 32 bit and DOWNLOAD_X86_64 for 64 bit, I dropped 32 bits for good, so DOWNLOAD is used for universal or 64 bit sources/blobs only. Almost any PC bought in the last 20 years is capable of running a 64 bit system. More and more software drop support for 32 bits, and it has become too difficult to add a multitude of patches and workarounds to re-enable it. There's disparity in Slackware itself with some packages having different features or even versions between Slackware and Slackware64. Besides, I have neither a powerful enough 32 bit PC, nor resources to run a VM/container of a fully installed Slackware.
7. Slackware is the only distro I know that executes its build scripts directly. CRUX, Arch and Gentoo (most notable examples, but also pretty much every other distro) use a master script that parses Pkgbuild/PKGBUILD/ebuild to build the package. This keeps the build scripts focused on just building thus potentially increasing a repo's maintainability at the cost of the master script's complexity.

# Caveats

- Admittedly, using a master script is more restrictive than a regular SlackBuild. While in a SlackBuild you can change every step as you see fit, in `sb` I have to handle every edge case by increasing the code's complexity and decreasing its maintainability. SlackBuilds themselves do look nicer, though.
- Slackware wasn't designed with package separation in mind, so it's not possible to put every package into /usr/local prefix, things like plugins, extensions and perl/python/ruby libraries require you to put them into their direct dependency's prefix. Try to keep things inside /usr/local (or whatever _PREFIX other than /usr you chose) unless absolutely necessary to have them in the system's default prefix.
