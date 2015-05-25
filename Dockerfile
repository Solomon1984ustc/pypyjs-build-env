
FROM 32bit/ubuntu:14.04 

MAINTAINER Albert-Jan Nijburg <albertjan@curit.com>

ENV LANG C.UTF-8
ENV EM_CACHE /var/cache/emscripten/cache
ENV EM_CONFIG /var/cache/emscripten/config

ADD Makefile /build/Makefile

RUN DEBIAN_FRONTEND=noninteractive \
    	apt-get update -y && \
    	apt-get install -y --no-install-recommends \
                ca-certificates \
                build-essential \
                subversion \
                git-core \
                vim \
                wget \
                libffi-dev \
                libgc-dev \
                libncurses-dev \
                libz-dev \
                pkg-config \
                python-dev \
                python-setuptools \
                libboost-system-dev \
                libboost-thread-dev \
                libboost-python-dev \
                groff groff-base manpages-dev

RUN make -C /build all

