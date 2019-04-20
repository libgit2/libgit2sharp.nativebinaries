FROM alpine:3.9
WORKDIR /nativebinaries
COPY . /nativebinaries/

RUN apk add --no-cache bash build-base cmake openssl-dev

CMD ["/bin/bash", "-c", "./build.libgit2.sh"]
