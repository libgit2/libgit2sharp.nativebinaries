FROM ubuntu:16.04

WORKDIR /nativebinaries
COPY . /nativebinaries/

RUN dpkg --add-architecture arm64 \
&& sed -i 's/deb/deb [arch=amd64]/g' /etc/apt/sources.list \
&& echo "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports xenial main universe" > /etc/apt/sources.list.d/arm64.list \
&& echo "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports xenial-updates main universe" > /etc/apt/sources.list.d/arm64-updates.list

RUN apt update \
&& apt -y install cmake pkg-config \
   crossbuild-essential-arm64 \
   pkg-config-aarch64-linux-gnu \
   libssl-dev:arm64

CMD ["/bin/bash", "-c", "./build.libgit2.sh"]
