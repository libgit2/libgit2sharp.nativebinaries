FROM centos:6
WORKDIR /nativebinaries
COPY . /nativebinaries/

RUN yum -y install cmake gcc make openssl-devel

CMD ["/bin/bash", "-c", "./build.libgit2.sh"]
