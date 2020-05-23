Skip to content
Search or jump to…

Pull requests
Issues
Marketplace
Explore
 
@Appietus 
Greg-Griffith
/
eccoin
forked from project-ecc/eccoin
2
031
 Code
 Pull requests 0 Actions
 Projects 0
 Wiki
 Security 0
 Insights
add automake and configure scripts. compiles OSX

import automake and configure scripts, thank you to thezerg and bch devs
for this
 master (project-ecc/eccoin#50)
Greg Griffith
Greg Griffith committed on Dec 31, 2017 
1 parent 531aa10 commit 1ba68c4661725fb868264ad8faa4581755420e9c
Showing  with 1,710 additions and 0 deletions.
 79  .travis.yml 
@@ -0,0 +1,79 @@
sudo: required
dist: trusty
os: linux
language: generic
cache:
  directories:
  - depends/built
  - depends/sdk-sources
  - $HOME/.ccache
env:
  global:
    - MAKEJOBS=-j3
    - RUN_TESTS=false
    - RUN_FORMATTING_CHECK=false
    - CHECK_DOC=0
    - BOOST_TEST_RANDOM=1$TRAVIS_BUILD_ID
    - CCACHE_SIZE=100M
    - CCACHE_TEMPDIR=/tmp/.ccache-temp
    - CCACHE_COMPRESS=1
    - BASE_OUTDIR=$TRAVIS_BUILD_DIR/out
    - SDK_URL=https://www.bitcoinunlimited.info/sdks
    - PYTHON_DEBUG=1
    - WINEDEBUG=fixme-all
    - PPA=ppa:bitcoin-unlimited/bu-ppa
  matrix:
# bitcoind
    - HOST=x86_64-unknown-linux-gnu PACKAGES="python3-zmq clang-format-3.8" DEP_OPTS="NO_QT=1 NO_UPNP=1 DEBUG=1" RUN_TESTS=true RUN_FORMATTING_CHECK=true GOAL="install" BITCOIN_CONFIG="--enable-zmq --enable-glibc-back-compat --enable-reduce-exports CPPFLAGS=-DDEBUG_LOCKORDER"
# ARM64
    - HOST=aarch64-linux-gnu PACKAGES="g++-aarch64-linux-gnu" DEP_OPTS="NO_QT=1" GOAL="install" BITCOIN_CONFIG="--enable-glibc-back-compat --enable-reduce-exports"
# ARMHF
    - HOST=arm-linux-gnueabihf PACKAGES="g++-arm-linux-gnueabihf" DEP_OPTS="NO_QT=1" GOAL="install" BITCOIN_CONFIG="--enable-glibc-back-compat --enable-reduce-exports"
# Win32
    - HOST=i686-w64-mingw32 DPKG_ADD_ARCH="i386" DEP_OPTS="NO_QT=1" PACKAGES="python3 nsis g++-mingw-w64-i686 wine1.6 bc" RUN_TESTS=true GOAL="install" BITCOIN_CONFIG="--enable-reduce-exports"
# 32-bit + dash
    - HOST=i686-pc-linux-gnu PACKAGES="g++-multilib bc python3-zmq" DEP_OPTS="NO_QT=1" RUN_TESTS=true GOAL="install" BITCOIN_CONFIG="--enable-zmq --enable-glibc-back-compat --enable-reduce-exports LDFLAGS=-static-libstdc++" USE_SHELL="/bin/dash"
# Win64
    - HOST=x86_64-w64-mingw32 DPKG_ADD_ARCH="i386" DEP_OPTS="NO_QT=1" PACKAGES="python3 nsis g++-mingw-w64-x86-64 wine1.6 bc" RUN_TESTS=true GOAL="install" BITCOIN_CONFIG="--enable-reduce-exports"
# x86_64 Linux, No wallet (uses qt5 dev package instead of depends Qt to speed up build and avoid timeout)
    - HOST=x86_64-unknown-linux-gnu PACKAGES="python3 qtbase5-dev qttools5-dev-tools protobuf-compiler libdbus-1-dev libharfbuzz-dev" DEP_OPTS="NO_WALLET=1 NO_QT=1 ALLOW_HOST_PACKAGES=1" RUN_TESTS=true GOAL="install" BITCOIN_CONFIG="--enable-glibc-back-compat --enable-reduce-exports"
# Cross-Mac
    - HOST=x86_64-apple-darwin11 PACKAGES="cmake imagemagick libcap-dev librsvg2-bin libz-dev libbz2-dev libtiff-tools python-dev" BITCOIN_CONFIG="--enable-reduce-exports" OSX_SDK=10.11 GOAL="deploy"
before_install:
    - export PATH=$(echo $PATH | tr ':' "\n" | sed '/\/opt\/python/d' | tr "\n" ":" | sed "s|::|:|g")
    #  temp fix with riak repo, by the way we don't need riak at all
    - sudo rm -vf /etc/apt/sources.list.d/*riak*
    - sudo apt-get update
install:
    - if [ -n "$PPA" ]; then travis_retry sudo add-apt-repository "$PPA" -y; fi
    - if [ -n "$DPKG_ADD_ARCH" ]; then sudo dpkg --add-architecture "$DPKG_ADD_ARCH" ; fi
    - if [ -n "$PACKAGES" ]; then travis_retry sudo apt-get update; fi
    - if [ -n "$PACKAGES" ]; then travis_retry sudo apt-get install --no-install-recommends --no-upgrade -qq libdb4.8-dev libdb4.8++-dev $PACKAGES; fi
before_script:
    - unset CC; unset CXX
    - if [ "$CHECK_DOC" = 1 ]; then contrib/devtools/check-doc.py; fi
    - mkdir -p depends/SDKs depends/sdk-sources
    - if [ -n "$OSX_SDK" -a ! -f depends/sdk-sources/MacOSX${OSX_SDK}.sdk.tar.gz ]; then curl --location --fail $SDK_URL/MacOSX${OSX_SDK}.sdk.tar.gz -o depends/sdk-sources/MacOSX${OSX_SDK}.sdk.tar.gz; fi
    - if [ -n "$OSX_SDK" -a -f depends/sdk-sources/MacOSX${OSX_SDK}.sdk.tar.gz ]; then tar -C depends/SDKs -xf depends/sdk-sources/MacOSX${OSX_SDK}.sdk.tar.gz; fi
    - make $MAKEJOBS -C depends HOST=$HOST $DEP_OPTS
script:
    - export TRAVIS_COMMIT_LOG=`git log --format=fuller -1`
    - if [ -n "$USE_SHELL" ]; then export CONFIG_SHELL="$USE_SHELL"; fi
    - OUTDIR=$BASE_OUTDIR/$TRAVIS_PULL_REQUEST/$TRAVIS_JOB_NUMBER-$HOST
    - BITCOIN_CONFIG_ALL="--disable-dependency-tracking --prefix=$TRAVIS_BUILD_DIR/depends/$HOST --bindir=$OUTDIR/bin --libdir=$OUTDIR/lib"
    - depends/$HOST/native/bin/ccache --max-size=$CCACHE_SIZE
    - test -n "$USE_SHELL" && eval '"$USE_SHELL" -c "./autogen.sh 2>&1 > autogen.out"' || ./autogen.sh 2>&1 > autogen.out || ( cat autogen.out && false)
    - mkdir build && cd build
    - echo "BITCOIN_CONFIG_ALL=$BITCOIN_CONFIG_ALL"
    - echo "BITCOIN_CONFIG=$BITCOIN_CONFIG"
    - echo "GOAL=$GOAL"
    - ../configure $BITCOIN_CONFIG_ALL $BITCOIN_CONFIG > configure.out || ( cat configure.out && cat config.log && false)
    - if [ "$RUN_FORMATTING_CHECK" = "true" ]; then make $MAKEJOBS check-formatting VERBOSE=1; fi
    - stdbuf -i0 -o0 -e0 make $MAKEJOBS $GOAL 2>&1 | ../contrib/devtools/buildsilence.py || ( echo "Build failure. Verbose build follows." && make $GOAL V=1 ; false )
    - export LD_LIBRARY_PATH=$TRAVIS_BUILD_DIR/depends/$HOST/lib
    - if [ "$RUN_TESTS" = "true" ] && { [ "$HOST" = "i686-w64-mingw32" ] || [ "$HOST" = "x86_64-w64-mingw32" ]; }; then travis_wait make $MAKEJOBS check VERBOSE=1; fi
    - if [ "$RUN_TESTS" = "true" ] && ! { [ "$HOST" = "i686-w64-mingw32" ] || [ "$HOST" = "x86_64-w64-mingw32" ]; }; then make $MAKEJOBS check VERBOSE=1; fi
    - if [ "$RUN_TESTS" = "true" ]; then qa/pull-tester/rpc-tests.py --coverage; fi
after_script:
    - echo $TRAVIS_COMMIT_RANGE
    - echo $TRAVIS_COMMIT_LOG
 218  Makefile.am 
@@ -0,0 +1,218 @@
ACLOCAL_AMFLAGS = -I build-aux/m4
SUBDIRS = src
.PHONY: deploy FORCE

GZIP_ENV="-9n"
export PYTHONPATH

if BUILD_BITCOIN_LIBS
pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = libbitcoinconsensus.pc
endif

BITCOIND_BIN=$(top_builddir)/src/$(BITCOIN_DAEMON_NAME)$(EXEEXT)
BITCOIN_QT_BIN=$(top_builddir)/src/qt/$(BITCOIN_GUI_NAME)$(EXEEXT)
BITCOIN_CLI_BIN=$(top_builddir)/src/$(BITCOIN_CLI_NAME)$(EXEEXT)
BITCOIN_WIN_INSTALLER=$(PACKAGE)-$(PACKAGE_VERSION)-win$(WINDOWS_BITS)-setup$(EXEEXT)

empty :=
space := $(empty) $(empty)

OSX_APP=Bitcoin-Qt.app
OSX_VOLNAME = $(subst $(space),-,$(PACKAGE_NAME))
OSX_DMG = $(OSX_VOLNAME).dmg
OSX_BACKGROUND_SVG=background.svg
OSX_BACKGROUND_IMAGE=background.tiff
OSX_BACKGROUND_IMAGE_DPIS=36 72
OSX_DSSTORE_GEN=$(top_srcdir)/contrib/macdeploy/custom_dsstore.py
OSX_DEPLOY_SCRIPT=$(top_srcdir)/contrib/macdeploy/macdeployqtplus
OSX_FANCY_PLIST=$(top_srcdir)/contrib/macdeploy/fancy.plist
OSX_INSTALLER_ICONS=$(top_srcdir)/src/qt/res/icons/bitcoin.icns
OSX_PLIST=$(top_builddir)/share/qt/Info.plist #not installed
OSX_QT_TRANSLATIONS = da,de,es,hu,ru,uk,zh_CN,zh_TW

DIST_DOCS = $(wildcard doc/*.md) $(wildcard doc/release-notes/*.md)

BIN_CHECKS=$(top_srcdir)/contrib/devtools/symbol-check.py \
           $(top_srcdir)/contrib/devtools/security-check.py

WINDOWS_PACKAGING = $(top_srcdir)/share/pixmaps/bitcoin.ico \
  $(top_srcdir)/share/pixmaps/nsis-header.bmp \
  $(top_srcdir)/share/pixmaps/nsis-wizard.bmp \
  $(top_srcdir)/doc/README_windows.txt

OSX_PACKAGING = $(OSX_DEPLOY_SCRIPT) $(OSX_FANCY_PLIST) $(OSX_INSTALLER_ICONS) \
  $(top_srcdir)/contrib/macdeploy/$(OSX_BACKGROUND_SVG) \
  $(OSX_DSSTORE_GEN) \
  $(top_srcdir)/contrib/macdeploy/detached-sig-apply.sh \
  $(top_srcdir)/contrib/macdeploy/detached-sig-create.sh

COVERAGE_INFO = baseline_filtered_combined.info baseline.info \
  leveldb_baseline.info test_bitcoin_filtered.info total_coverage.info \
  baseline_filtered.info rpc_test.info rpc_test_filtered.info \
  leveldb_baseline_filtered.info test_bitcoin_coverage.info test_bitcoin.info

dist-hook:
	-$(GIT) archive --format=tar HEAD -- src/clientversion.cpp | $(AMTAR) -C $(top_distdir) -xf -

$(BITCOIN_WIN_INSTALLER): all-recursive
	$(MKDIR_P) $(top_builddir)/release
	STRIPPROG="$(STRIP)" $(INSTALL_STRIP_PROGRAM) $(BITCOIND_BIN) $(top_builddir)/release
	STRIPPROG="$(STRIP)" $(INSTALL_STRIP_PROGRAM) $(BITCOIN_QT_BIN) $(top_builddir)/release
	STRIPPROG="$(STRIP)" $(INSTALL_STRIP_PROGRAM) $(BITCOIN_CLI_BIN) $(top_builddir)/release
	@test -f $(MAKENSIS) && $(MAKENSIS) -V2 $(top_builddir)/share/setup.nsi || \
	  echo error: could not build $@
	@echo built $@

$(if $(findstring src/,$(MAKECMDGOALS)),$(MAKECMDGOALS), none): FORCE
	$(MAKE) -C src $(patsubst src/%,%,$@)

$(OSX_APP)/Contents/PkgInfo:
	$(MKDIR_P) $(@D)
	@echo "APPL????" > $@

$(OSX_APP)/Contents/Resources/empty.lproj:
	$(MKDIR_P) $(@D)
	@touch $@ 

$(OSX_APP)/Contents/Info.plist: $(OSX_PLIST)
	$(MKDIR_P) $(@D)
	$(INSTALL_DATA) $< $@

$(OSX_APP)/Contents/Resources/bitcoin.icns: $(OSX_INSTALLER_ICONS)
	$(MKDIR_P) $(@D)
	$(INSTALL_DATA) $< $@

$(OSX_APP)/Contents/MacOS/Bitcoin-Qt: $(BITCOIN_QT_BIN)
	$(MKDIR_P) $(@D)
	STRIPPROG="$(STRIP)" $(INSTALL_STRIP_PROGRAM)  $< $@

$(OSX_APP)/Contents/Resources/Base.lproj/InfoPlist.strings:
	$(MKDIR_P) $(@D)
	echo '{	CFBundleDisplayName = "$(PACKAGE_NAME)"; CFBundleName = "$(PACKAGE_NAME)"; }' > $@

OSX_APP_BUILT=$(OSX_APP)/Contents/PkgInfo $(OSX_APP)/Contents/Resources/empty.lproj \
  $(OSX_APP)/Contents/Resources/bitcoin.icns $(OSX_APP)/Contents/Info.plist \
  $(OSX_APP)/Contents/MacOS/Bitcoin-Qt $(OSX_APP)/Contents/Resources/Base.lproj/InfoPlist.strings

osx_volname:
	echo $(OSX_VOLNAME) >$@

if BUILD_DARWIN
$(OSX_DMG): $(OSX_APP_BUILT) $(OSX_PACKAGING)
	$(OSX_DEPLOY_SCRIPT) $(OSX_APP) -add-qt-tr $(OSX_QT_TRANSLATIONS) -translations-dir=$(QT_TRANSLATION_DIR) -dmg -fancy $(OSX_FANCY_PLIST) -verbose 2 -volname $(OSX_VOLNAME)

deploydir: $(OSX_DMG)
else
APP_DIST_DIR=$(top_builddir)/dist
APP_DIST_EXTRAS=$(APP_DIST_DIR)/.background/$(OSX_BACKGROUND_IMAGE) $(APP_DIST_DIR)/.DS_Store $(APP_DIST_DIR)/Applications

$(APP_DIST_DIR)/Applications:
	@rm -f $@
	@cd $(@D); $(LN_S) /Applications $(@F)

$(APP_DIST_EXTRAS): $(APP_DIST_DIR)/$(OSX_APP)/Contents/MacOS/Bitcoin-Qt

$(OSX_DMG): $(APP_DIST_EXTRAS)
	$(GENISOIMAGE) -no-cache-inodes -D -l -probe -V "$(OSX_VOLNAME)" -no-pad -r -dir-mode 0755 -apple -o $@ dist

dpi%.$(OSX_BACKGROUND_IMAGE): contrib/macdeploy/$(OSX_BACKGROUND_SVG)
	sed 's/PACKAGE_NAME/$(PACKAGE_NAME)/' < "$<" | $(RSVG_CONVERT) -f png -d $* -p $* | $(IMAGEMAGICK_CONVERT) - $@
OSX_BACKGROUND_IMAGE_DPIFILES := $(foreach dpi,$(OSX_BACKGROUND_IMAGE_DPIS),dpi$(dpi).$(OSX_BACKGROUND_IMAGE))
$(APP_DIST_DIR)/.background/$(OSX_BACKGROUND_IMAGE): $(OSX_BACKGROUND_IMAGE_DPIFILES)
	$(MKDIR_P) $(@D)
	$(TIFFCP) -c none $(OSX_BACKGROUND_IMAGE_DPIFILES) $@

$(APP_DIST_DIR)/.DS_Store: $(OSX_DSSTORE_GEN)
	$< "$@" "$(OSX_VOLNAME)"

$(APP_DIST_DIR)/$(OSX_APP)/Contents/MacOS/Bitcoin-Qt: $(OSX_APP_BUILT) $(OSX_PACKAGING)
	INSTALLNAMETOOL=$(INSTALLNAMETOOL)  OTOOL=$(OTOOL) STRIP=$(STRIP) $(OSX_DEPLOY_SCRIPT) $(OSX_APP) -translations-dir=$(QT_TRANSLATION_DIR) -add-qt-tr $(OSX_QT_TRANSLATIONS) -verbose 2

deploydir: $(APP_DIST_EXTRAS)
endif

if TARGET_DARWIN
appbundle: $(OSX_APP_BUILT)
deploy: $(OSX_DMG)
endif
if TARGET_WINDOWS
deploy: $(BITCOIN_WIN_INSTALLER)
endif

$(BITCOIN_QT_BIN): FORCE
	$(MAKE) -C src qt/$(@F)

$(BITCOIND_BIN): FORCE
	$(MAKE) -C src $(@F)

$(BITCOIN_CLI_BIN): FORCE
	$(MAKE) -C src $(@F)

if USE_LCOV

baseline.info:
	$(LCOV) -c -i -d $(abs_builddir)/src -o $@

baseline_filtered.info: baseline.info
	$(LCOV) -r $< "/usr/include/*" -o $@

leveldb_baseline.info: baseline_filtered.info
	$(LCOV) -c -i -d $(abs_builddir)/src/leveldb -b $(abs_builddir)/src/leveldb -o $@

leveldb_baseline_filtered.info: leveldb_baseline.info
	$(LCOV) -r $< "/usr/include/*" -o $@

baseline_filtered_combined.info: leveldb_baseline_filtered.info baseline_filtered.info
	$(LCOV) -a leveldb_baseline_filtered.info -a baseline_filtered.info -o $@

test_bitcoin.info: baseline_filtered_combined.info
	$(MAKE) -C src/ check
	$(LCOV) -c -d $(abs_builddir)/src -t test_bitcoin -o $@
	$(LCOV) -z -d $(abs_builddir)/src
	$(LCOV) -z -d $(abs_builddir)/src/leveldb

test_bitcoin_filtered.info: test_bitcoin.info
	$(LCOV) -r $< "/usr/include/*" -o $@

rpc_test.info: test_bitcoin_filtered.info
	-@TIMEOUT=15 python qa/pull-tester/rpc-tests.py $(EXTENDED_RPC_TESTS)
	$(LCOV) -c -d $(abs_builddir)/src --t rpc-tests -o $@
	$(LCOV) -z -d $(abs_builddir)/src
	$(LCOV) -z -d $(abs_builddir)/src/leveldb

rpc_test_filtered.info: rpc_test.info
	$(LCOV) -r $< "/usr/include/*" -o $@

test_bitcoin_coverage.info: baseline_filtered_combined.info test_bitcoin_filtered.info
	$(LCOV) -a baseline_filtered.info -a leveldb_baseline_filtered.info -a test_bitcoin_filtered.info -o $@

total_coverage.info: baseline_filtered_combined.info test_bitcoin_filtered.info rpc_test_filtered.info
	$(LCOV) -a baseline_filtered.info -a leveldb_baseline_filtered.info -a test_bitcoin_filtered.info -a rpc_test_filtered.info -o $@ | $(GREP) "\%" | $(AWK) '{ print substr($$3,2,50) "/" $$5 }' > coverage_percent.txt

test_bitcoin.coverage/.dirstamp:  test_bitcoin_coverage.info
	$(GENHTML) -s $< -o $(@D)
	@touch $@

total.coverage/.dirstamp: total_coverage.info
	$(GENHTML) -s $< -o $(@D)
	@touch $@

cov: test_bitcoin.coverage/.dirstamp total.coverage/.dirstamp

endif

check-formatting:
	$(MAKE) -C src $@

dist_noinst_SCRIPTS = autogen.sh

EXTRA_DIST = $(top_srcdir)/share/genbuild.sh qa/pull-tester/rpc-tests.py qa/pull-tester/test_classes.py qa/rpc-tests $(DIST_DOCS) $(WINDOWS_PACKAGING) $(OSX_PACKAGING) $(BIN_CHECKS)

CLEANFILES = $(OSX_DMG) $(BITCOIN_WIN_INSTALLER)

.INTERMEDIATE: $(COVERAGE_INFO)

clean-local:
	rm -rf coverage_percent.txt test_bitcoin.coverage/ total.coverage/ qa/tmp/ cache/ $(OSX_APP)
	rm -rf qa/pull-tester/__pycache__
 9  autogen.sh 
@@ -0,0 +1,9 @@
#!/bin/sh
set -e
srcdir="$(dirname $0)"
cd "$srcdir"
if [ -z ${LIBTOOLIZE} ] && GLIBTOOLIZE="`which glibtoolize 2>/dev/null`"; then
  LIBTOOLIZE="${GLIBTOOLIZE}"
  export LIBTOOLIZE
fi
autoreconf --install --force --warnings=all
 1,179  configure.ac 
Large diffs are not rendered by default.

 11  libbitcoinconsensus.pc.in 
@@ -0,0 +1,11 @@
prefix=@prefix@
exec_prefix=@exec_prefix@
libdir=@libdir@
includedir=@includedir@

Name: @PACKAGE_NAME@ consensus library
Description: Library for the Bitcoin consensus protocol.
Version: @PACKAGE_VERSION@
Libs: -L${libdir} -lbitcoinconsensus
Cflags: -I${includedir}
Requires.private: libcrypto
 214  pkg.m4 
@@ -0,0 +1,214 @@
# pkg.m4 - Macros to locate and utilise pkg-config.            -*- Autoconf -*-
# serial 1 (pkg-config-0.24)
# 
# Copyright © 2004 Scott James Remnant <scott@netsplit.com>.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# As a special exception to the GNU General Public License, if you
# distribute this file as part of a program that contains a
# configuration script generated by Autoconf, you may include it under
# the same distribution terms that you use for the rest of that program.

# PKG_PROG_PKG_CONFIG([MIN-VERSION])
# ----------------------------------
AC_DEFUN([PKG_PROG_PKG_CONFIG],
[m4_pattern_forbid([^_?PKG_[A-Z_]+$])
m4_pattern_allow([^PKG_CONFIG(_(PATH|LIBDIR|SYSROOT_DIR|ALLOW_SYSTEM_(CFLAGS|LIBS)))?$])
m4_pattern_allow([^PKG_CONFIG_(DISABLE_UNINSTALLED|TOP_BUILD_DIR|DEBUG_SPEW)$])
AC_ARG_VAR([PKG_CONFIG], [path to pkg-config utility])
AC_ARG_VAR([PKG_CONFIG_PATH], [directories to add to pkg-config's search path])
AC_ARG_VAR([PKG_CONFIG_LIBDIR], [path overriding pkg-config's built-in search path])
if test "x$ac_cv_env_PKG_CONFIG_set" != "xset"; then
	AC_PATH_TOOL([PKG_CONFIG], [pkg-config])
fi
if test -n "$PKG_CONFIG"; then
	_pkg_min_version=m4_default([$1], [0.9.0])
	AC_MSG_CHECKING([pkg-config is at least version $_pkg_min_version])
	if $PKG_CONFIG --atleast-pkgconfig-version $_pkg_min_version; then
		AC_MSG_RESULT([yes])
	else
		AC_MSG_RESULT([no])
		PKG_CONFIG=""
	fi
fi[]dnl
])# PKG_PROG_PKG_CONFIG

# PKG_CHECK_EXISTS(MODULES, [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
#
# Check to see whether a particular set of modules exists.  Similar
# to PKG_CHECK_MODULES(), but does not set variables or print errors.
#
# Please remember that m4 expands AC_REQUIRE([PKG_PROG_PKG_CONFIG])
# only at the first occurence in configure.ac, so if the first place
# it's called might be skipped (such as if it is within an "if", you
# have to call PKG_CHECK_EXISTS manually
# --------------------------------------------------------------
AC_DEFUN([PKG_CHECK_EXISTS],
[AC_REQUIRE([PKG_PROG_PKG_CONFIG])dnl
if test -n "$PKG_CONFIG" && \
    AC_RUN_LOG([$PKG_CONFIG --exists --print-errors "$1"]); then
  m4_default([$2], [:])
m4_ifvaln([$3], [else
  $3])dnl
fi])

# _PKG_CONFIG([VARIABLE], [COMMAND], [MODULES])
# ---------------------------------------------
m4_define([_PKG_CONFIG],
[if test -n "$$1"; then
    pkg_cv_[]$1="$$1"
 elif test -n "$PKG_CONFIG"; then
    PKG_CHECK_EXISTS([$3],
                     [pkg_cv_[]$1=`$PKG_CONFIG --[]$2 "$3" 2>/dev/null`
		      test "x$?" != "x0" && pkg_failed=yes ],
		     [pkg_failed=yes])
 else
    pkg_failed=untried
fi[]dnl
])# _PKG_CONFIG

# _PKG_SHORT_ERRORS_SUPPORTED
# -----------------------------
AC_DEFUN([_PKG_SHORT_ERRORS_SUPPORTED],
[AC_REQUIRE([PKG_PROG_PKG_CONFIG])
if $PKG_CONFIG --atleast-pkgconfig-version 0.20; then
        _pkg_short_errors_supported=yes
else
        _pkg_short_errors_supported=no
fi[]dnl
])# _PKG_SHORT_ERRORS_SUPPORTED


# PKG_CHECK_MODULES(VARIABLE-PREFIX, MODULES, [ACTION-IF-FOUND],
# [ACTION-IF-NOT-FOUND])
#
#
# Note that if there is a possibility the first call to
# PKG_CHECK_MODULES might not happen, you should be sure to include an
# explicit call to PKG_PROG_PKG_CONFIG in your configure.ac
#
#
# --------------------------------------------------------------
AC_DEFUN([PKG_CHECK_MODULES],
[AC_REQUIRE([PKG_PROG_PKG_CONFIG])dnl
AC_ARG_VAR([$1][_CFLAGS], [C compiler flags for $1, overriding pkg-config])dnl
AC_ARG_VAR([$1][_LIBS], [linker flags for $1, overriding pkg-config])dnl
pkg_failed=no
AC_MSG_CHECKING([for $1])
_PKG_CONFIG([$1][_CFLAGS], [cflags], [$2])
_PKG_CONFIG([$1][_LIBS], [libs], [$2])
m4_define([_PKG_TEXT], [Alternatively, you may set the environment variables $1[]_CFLAGS
and $1[]_LIBS to avoid the need to call pkg-config.
See the pkg-config man page for more details.])
if test $pkg_failed = yes; then
   	AC_MSG_RESULT([no])
        _PKG_SHORT_ERRORS_SUPPORTED
        if test $_pkg_short_errors_supported = yes; then
	        $1[]_PKG_ERRORS=`$PKG_CONFIG --short-errors --print-errors --cflags --libs "$2" 2>&1`
        else 
	        $1[]_PKG_ERRORS=`$PKG_CONFIG --print-errors --cflags --libs "$2" 2>&1`
        fi
	# Put the nasty error message in config.log where it belongs
	echo "$$1[]_PKG_ERRORS" >&AS_MESSAGE_LOG_FD
	m4_default([$4], [AC_MSG_ERROR(
[Package requirements ($2) were not met:
$$1_PKG_ERRORS
Consider adjusting the PKG_CONFIG_PATH environment variable if you
installed software in a non-standard prefix.
_PKG_TEXT])[]dnl
        ])
elif test $pkg_failed = untried; then
     	AC_MSG_RESULT([no])
	m4_default([$4], [AC_MSG_FAILURE(
[The pkg-config script could not be found or is too old.  Make sure it
is in your PATH or set the PKG_CONFIG environment variable to the full
path to pkg-config.
_PKG_TEXT
To get pkg-config, see <http://pkg-config.freedesktop.org/>.])[]dnl
        ])
else
	$1[]_CFLAGS=$pkg_cv_[]$1[]_CFLAGS
	$1[]_LIBS=$pkg_cv_[]$1[]_LIBS
        AC_MSG_RESULT([yes])
	$3
fi[]dnl
])# PKG_CHECK_MODULES


# PKG_INSTALLDIR(DIRECTORY)
# -------------------------
# Substitutes the variable pkgconfigdir as the location where a module
# should install pkg-config .pc files. By default the directory is
# $libdir/pkgconfig, but the default can be changed by passing
# DIRECTORY. The user can override through the --with-pkgconfigdir
# parameter.
AC_DEFUN([PKG_INSTALLDIR],
[m4_pushdef([pkg_default], [m4_default([$1], ['${libdir}/pkgconfig'])])
m4_pushdef([pkg_description],
    [pkg-config installation directory @<:@]pkg_default[@:>@])
AC_ARG_WITH([pkgconfigdir],
    [AS_HELP_STRING([--with-pkgconfigdir], pkg_description)],,
    [with_pkgconfigdir=]pkg_default)
AC_SUBST([pkgconfigdir], [$with_pkgconfigdir])
m4_popdef([pkg_default])
m4_popdef([pkg_description])
]) dnl PKG_INSTALLDIR


# PKG_NOARCH_INSTALLDIR(DIRECTORY)
# -------------------------
# Substitutes the variable noarch_pkgconfigdir as the location where a
# module should install arch-independent pkg-config .pc files. By
# default the directory is $datadir/pkgconfig, but the default can be
# changed by passing DIRECTORY. The user can override through the
# --with-noarch-pkgconfigdir parameter.
AC_DEFUN([PKG_NOARCH_INSTALLDIR],
[m4_pushdef([pkg_default], [m4_default([$1], ['${datadir}/pkgconfig'])])
m4_pushdef([pkg_description],
    [pkg-config arch-independent installation directory @<:@]pkg_default[@:>@])
AC_ARG_WITH([noarch-pkgconfigdir],
    [AS_HELP_STRING([--with-noarch-pkgconfigdir], pkg_description)],,
    [with_noarch_pkgconfigdir=]pkg_default)
AC_SUBST([noarch_pkgconfigdir], [$with_noarch_pkgconfigdir])
m4_popdef([pkg_default])
m4_popdef([pkg_description])
]) dnl PKG_NOARCH_INSTALLDIR


# PKG_CHECK_VAR(VARIABLE, MODULE, CONFIG-VARIABLE,
# [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
# -------------------------------------------
# Retrieves the value of the pkg-config variable for the given module.
AC_DEFUN([PKG_CHECK_VAR],
[AC_REQUIRE([PKG_PROG_PKG_CONFIG])dnl
AC_ARG_VAR([$1], [value of $3 for $2, overriding pkg-config])dnl
_PKG_CONFIG([$1], [variable="][$3]["], [$2])
AS_VAR_COPY([$1], [pkg_cv_][$1])
AS_VAR_IF([$1], [""], [$5], [$4])dnl
])# PKG_CHECK_VAR
0 comments on commit 1ba68c4
@Appietus
 
 
Leave a comment

Attach files by dragging & dropping, selecting or pasting them.
 You’re not receiving notifications from this thread.
© 2020 GitHub, Inc.
Terms
Privacy
Security
Status
Help
Contact GitHub
Pricing
API
Training
Blog
About
