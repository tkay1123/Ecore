#!/bin/bash
#
# Copyright (c) 2018 The BitcoinUnlimited developers
# Copyright (c) 2019 The Eccoin developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

cd "build" || (echo "could not enter distdir build"; exit 1)

BEGIN_FOLD unit-tests
if [ "$RUN_TESTS" = "true" ] && ! { [ "$HOST" = "i686-w64-mingw32" ] || [ "$HOST" = "x86_64-w64-mingw32" ]; }; then
  DOCKER_EXEC LD_LIBRARY_PATH=$TRAVIS_BUILD_DIR/depends/$HOST/lib make $MAKEJOBS check VERBOSE=1;
fi
END_FOLD

BEGIN_FOLD functional-tests
if [ "$RUN_TESTS" = "true" ]; then DOCKER_EXEC qa/pull-tester/rpc-tests.py --coverage --no-ipv6-rpc-listen; fi
END_FOLD
