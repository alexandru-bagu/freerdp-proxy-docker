FROM ubuntu:21.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt -qq update && apt install -y ninja-build build-essential debhelper cdbs dpkg-dev autotools-dev \
    cmake pkg-config xmlto libssl-dev docbook-xsl xsltproc git libsystemd-dev libz-dev

RUN mkdir /build
RUN git clone https://github.com/alexandru-bagu/FreeRDP /build/FreeRDP
WORKDIR /build/FreeRDP
RUN git fetch; git checkout f2684932776b23ec5161f808a01833adabd4a528 
RUN cmake -DCHANNEL_URBDRC=OFF -DWITH_PROXY=ON -DWITH_SHADOW=OFF -DWITH_SERVER=ON -DBUILD_SHARED_LIBS=ON
RUN cmake --build . -j 16
RUN cmake --build . --target install

FROM ubuntu:21.04
USER root
RUN mkdir -p /root
WORKDIR /root
RUN apt -qq update && apt install -y libssl1.1 mysql-client jq curl
COPY --from=0 /usr/local /usr/local
COPY config.ini /root
COPY freerdp-guacamole-auth.sh /root/freerdp-proxy-authentication
COPY entrypoint.sh /root/entrypoint.sh
EXPOSE 3389
ENTRYPOINT /bin/bash entrypoint.sh