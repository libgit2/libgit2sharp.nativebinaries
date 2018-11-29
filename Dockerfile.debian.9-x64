FROM debian:9
WORKDIR /nativebinaries
COPY . /nativebinaries/

RUN apt update && apt -y install cmake gcc libssl-dev pkg-config

CMD ["/bin/bash", "-c", "./build.libgit2.sh"]
