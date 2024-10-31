#!/bin/bash

set -e
echo "building for $RID"

if [[ $RID =~ arm64 ]]; then
    arch="arm64"
    cc_arch="arm64"
elif [[ $RID =~ arm ]]; then
    arch="armhf"
    cc_arch="armhf"
elif [[ $RID == linux-ppc64le ]]; then
    arch="ppc64le"
    cc_arch="powerpc64le"
elif [[ $RID == linux-musl-ppc64le ]]; then
    arch="ppc64le"
    cc_arch="ppc64le"
else
    arch="amd64"
    cc_arch="amd64"
fi

if [[ $RID == linux-musl* ]]; then
    dockerfile="Dockerfile.linux-musl"
else
    dockerfile="Dockerfile.linux"
fi

docker buildx build -t $RID -f $dockerfile --build-arg ARCH=$arch --build-arg CC_ARCH=$cc_arch .

docker run -t -e RID=$RID --name=$RID $RID

docker cp $RID:/nativebinaries/nuget.package/runtimes nuget.package

docker rm $RID
