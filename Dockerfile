FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt -qq update
RUN apt install -y ninja-build build-essential debhelper cdbs dpkg-dev autotools-dev \
    cmake pkg-config xmlto libssl-dev docbook-xsl xsltproc libxkbfile-dev libx11-dev libwayland-dev libxrandr-dev \
    libxi-dev libxrender-dev libxext-dev libxinerama-dev libxfixes-dev libxcursor-dev libxv-dev libxdamage-dev \
    libxtst-dev libcups2-dev libpcsclite-dev libasound2-dev libpulse-dev libjpeg-dev libgsm1-dev libusb-1.0-0-dev \
    libudev-dev libdbus-glib-1-dev uuid-dev libxml2-dev libgstreamer1.0-dev  libgstreamer-plugins-base1.0-dev \
    libfaad-dev libfaac-dev libavutil-dev libavcodec-dev libavresample-dev git libsystemd-dev

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
RUN cmake -DCHANNEL_URBDRC=ON -DWITH_DSP_FFMPEG=ON -DWITH_CUPS=ON -DWITH_PULSE=ON -DWITH_FAAC=ON -DWITH_FAAD2=ON \
    -DWITH_GSM=ON -DWITH_SERVER=ON -DWITH_WAYLAND=OFF -DWITH_JPEG=ON -DMONOLITHIC_BUILD=ON -DBUILD_SHARED_LIBS=ON -DWITH_X11=OFF \
    -DWITH_PROXY_MODULES=ON .
RUN cmake --build .
RUN cmake --build . --target install

RUN mkdir -p /root
USER root
WORKDIR /root
COPY config.ini /root
COPY start.sh /root
COPY freerdp-external-target-resolve.sh /root/freerdp-external-target-resolve
RUN winpr-makecert -rdp -path . server
EXPOSE 3389
ENTRYPOINT /root/start.sh