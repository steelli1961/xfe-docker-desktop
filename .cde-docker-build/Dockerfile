FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git automake autoconf libtool pkg-config cmake \
    xorg x11-xserver-utils xauth xinit openmotif libx11-dev libxmu-dev libxaw7-dev libice-dev libsm-dev libxt-dev libxext-dev libfontconfig1-dev libfreetype6-dev libxfixes-dev libssl-dev curl ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /src
