#!/bin/bash

set -e
echo "building for $RID"

if [[ $RID =~ arm64 ]]; then
    arch="arm64"
elif [[ $RID =~ arm ]]; then
    arch="arm/v7"
elif [[ $RID =~ ppc64le ]]; then
    arch="ppc64le"
else
    arch="amd64"
fi

if [[ $RID == linux-musl* ]]; then
    dockerfile="Dockerfile.linux-musl"
else
    dockerfile="Dockerfile.linux"
fi

docker buildx build -t $RID -f $dockerfile --platform=linux/$arch .

docker run -t -e RID=$RID --name=$RID $RID

docker cp $RID:/nativebinaries/nuget.package/runtimes nuget.package

docker rm $RID
