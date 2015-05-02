#!/bin/bash

if [ $TRAVIS_SECURE_ENV_VARS == "true" ]; then

pushd nuget.package

zip -r binaries.zip libgit2

BINTRAY_API_USER="nulltoken"

curl -T binaries.zip -u$BINTRAY_API_USER:$BINTRAY_API_KEY https://api.bintray.com/content/libgit2/compiled-binaries/$TRAVIS_OS_NAME/$TRAVIS_BUILD_NUMBER/binaries-$TRAVIS_OS_NAME-$TRAVIS_BUILD_NUMBER.zip?publish=1

popd

fi
