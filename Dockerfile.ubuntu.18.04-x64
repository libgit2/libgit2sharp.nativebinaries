FROM ubuntu:18.04
WORKDIR /nativebinaries
COPY . /nativebinaries/

RUN apt update && apt -y install cmake libssl-dev pkg-config

CMD ["/bin/bash", "-c", "./build.libgit2.sh"]
