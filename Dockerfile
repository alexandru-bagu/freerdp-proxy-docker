FROM ubuntu:21.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt -qq update && apt install -y ninja-build build-essential debhelper cdbs dpkg-dev autotools-dev \
    cmake pkg-config xmlto libssl-dev docbook-xsl xsltproc git libsystemd-dev libz-dev

RUN mkdir /build
RUN git clone https://github.com/alexandru-bagu/FreeRDP /build/FreeRDP
WORKDIR /build/FreeRDP
RUN git fetch; git checkout f3c6b5ea08ccacb7ca30780b1e18fb2f85a58733 
RUN cmake -DCHANNEL_URBDRC=OFF -DWITH_PROXY=ON -DWITH_SHADOW=OFF -DWITH_SERVER=ON -DBUILD_SHARED_LIBS=ON
RUN cmake --build . -j 16
RUN cmake --build . --target install

FROM ubuntu:21.04
USER root
RUN mkdir -p /root
WORKDIR /root
RUN apt -qq update && apt install -y libssl1.1 mysql-client jq curl
RUN apt install -y libasan6 llvm
COPY --from=0 /usr/local /usr/local
RUN winpr-makecert -silent -path certificates -n rdp-server -y 10
RUN winpr-makecert -silent -path certificates -n rdp-private
COPY config.ini /root
COPY freerdp-static-auth.sh /root/freerdp-proxy-authentication
EXPOSE 3389
ENTRYPOINT /usr/local/bin/freerdp-proxy config.ini