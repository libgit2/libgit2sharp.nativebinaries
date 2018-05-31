#!/bin/bash

if [ $TRAVIS_SECURE_ENV_VARS == "true" ]; then

pushd nuget.package

zip -r binaries.zip runtimes

BINTRAY_API_USER="nulltoken"

curl -T binaries.zip -u$BINTRAY_API_USER:$BINTRAY_API_KEY https://api.bintray.com/content/libgit2/compiled-binaries/libgit2/$TRAVIS_BUILD_NUMBER/binaries-$RID-$TRAVIS_BUILD_NUMBER.zip?publish=1

printf "\n\n-> https://dl.bintray.com/libgit2/compiled-binaries/binaries-%s-%s.zip\n\n" "$RID" "$TRAVIS_BUILD_NUMBER"

popd

fi
