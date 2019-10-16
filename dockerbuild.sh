#!/bin/bash

set -e

docker build -t $RID -f Dockerfile.$RID .

docker run -it -e RID=$RID --name=$RID $RID

docker cp $RID:/nativebinaries/nuget.package/runtimes nuget.package

docker rm $RID
