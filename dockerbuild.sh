#!/bin/bash

set -e
echo "building for $RID"

docker buildx build -t $RID -f Dockerfile.$RID .

docker run -t -e RID=$RID --name=$RID $RID

docker cp $RID:/nativebinaries/nuget.package/runtimes nuget.package

docker rm $RID
