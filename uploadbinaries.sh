#!/bin/bash

pushd nuget.package

zip -r binaries.zip libgit2

BINTRAYUSER="bording"
BINTRAYKEY="51d19b77bad09256980e7904f540bf012436a32f"

curl -T binaries.zip -u$BINTRAYUSER:$BINTRAYKEY https://api.bintray.com/content/bording/generic/$TRAVIS_OS_NAME/$TRAVIS_BUILD_NUMBER/binaries-$TRAVIS_OS_NAME-$TRAVIS_BUILD_NUMBER.zip?publish=1

popd
