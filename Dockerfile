FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt -qq update && apt install -y ninja-build build-essential debhelper cdbs dpkg-dev autotools-dev \
    cmake pkg-config xmlto libssl-dev docbook-xsl xsltproc git libsystemd-dev libz-dev

RUN mkdir /build && \
    cd /build && \
    git clone https://github.com/alexandru-bagu/FreeRDP.git && \
    cd FreeRDP && \
    git checkout 4105be2 && \
    rm -rf /build/FreeRDP/server/proxy/modules/demo
WORKDIR /build/FreeRDP
RUN cmake –GNinja -DCHANNEL_URBDRC=OFF -DWITH_SERVER=ON -DBUILD_SHARED_LIBS=ON -DWITH_PROXY_MODULES=ON -DPROXY_PLUGINDIR=/usr/local/freerdp/plugins .
RUN cmake --build . -j 16
RUN cmake --build . --target install

FROM ubuntu:20.04
RUN mkdir -p /root
RUN apt -qq update && apt install -y libssl1.1 mysql-client jq curl
COPY --from=0 /usr/local /usr/local
USER root
WORKDIR /root
COPY config.ini /root
COPY start.sh /root
COPY freerdp-external-target-resolve.sh /root/freerdp-external-target-resolve
RUN winpr-makecert -rdp -path . server
EXPOSE 3389
ENTRYPOINT /root/start.sh
