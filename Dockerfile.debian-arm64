FROM debian:9
WORKDIR /nativebinaries
COPY . /nativebinaries/

RUN dpkg --add-architecture arm64

RUN apt update \
&& apt -y install cmake pkg-config \
   crossbuild-essential-arm64 \
   libssl-dev:arm64

CMD ["/bin/bash", "-c", "./build.libgit2.sh"]
