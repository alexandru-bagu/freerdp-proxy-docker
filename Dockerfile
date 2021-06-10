FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt -qq update && apt install -y ninja-build build-essential debhelper cdbs dpkg-dev autotools-dev \
    cmake pkg-config xmlto libssl-dev docbook-xsl xsltproc git libsystemd-dev libz-dev

RUN mkdir /build && \
    cd /build && \
    git clone https://github.com/FreeRDP/FreeRDP.git && \
    git clone https://github.com/alexandru-bagu/freerdp-proxy-external-target-resolve.git && \
    cd FreeRDP && \
    git checkout 06315d0 && \
    cd server/proxy/modules && \
    mkdir external-target-resolve && \
    cp -a /build/freerdp-proxy-external-target-resolve/external-target-resolve/. external-target-resolve
WORKDIR /build/FreeRDP
RUN cmake -DCHANNEL_URBDRC=OFF -DWITH_SERVER=ON -DMONOLITHIC_BUILD=ON -DBUILD_SHARED_LIBS=ON \
    -DWITH_PROXY_MODULES=ON -DPROXY_PLUGINDIR=/usr/local/freerdp/plugins .
RUN cmake --build .
RUN cmake --build . --target install

FROM ubuntu:20.04
RUN mkdir -p /root
COPY --from=0 /usr/local /usr/local
RUN apt -qq update && apt install -y libssl1.1 mysql-client
USER root
WORKDIR /root
COPY config.ini /root
COPY start.sh /root
COPY freerdp-external-target-resolve.sh /root/freerdp-external-target-resolve
RUN winpr-makecert -rdp -path . server
EXPOSE 3389
ENTRYPOINT /root/start.sh