FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt -qq update
RUN apt install -y ninja-build build-essential debhelper cdbs dpkg-dev autotools-dev \
    cmake pkg-config xmlto libssl-dev docbook-xsl xsltproc libxkbfile-dev libx11-dev libwayland-dev libxrandr-dev \
    libxi-dev libxrender-dev libxext-dev libxinerama-dev libxfixes-dev libxcursor-dev libxv-dev libxdamage-dev \
    libxtst-dev libcups2-dev libpcsclite-dev libasound2-dev libpulse-dev libjpeg-dev libgsm1-dev libusb-1.0-0-dev \
    libudev-dev libdbus-glib-1-dev uuid-dev libxml2-dev libgstreamer1.0-dev  libgstreamer-plugins-base1.0-dev \
    libfaad-dev libfaac-dev libavutil-dev libavcodec-dev libavresample-dev git libsystemd-dev

RUN mkdir /build && cd /build && git clone https://github.com/FreeRDP/FreeRDP.git && cd FreeRDP && git checkout 2.3.2
WORKDIR /build/FreeRDP
RUN cmake -DCHANNEL_URBDRC=ON -DWITH_DSP_FFMPEG=ON -DWITH_CUPS=ON -DWITH_PULSE=ON -DWITH_FAAC=ON -DWITH_FAAD2=ON \
    -DWITH_GSM=ON -DWITH_SERVER=ON -DWITH_WAYLAND=OFF -DWITH_JPEG=ON -DMONOLITHIC_BUILD=ON -DBUILD_SHARED_LIBS=OFF -DWITH_X11=OFF .
RUN cmake --build .
RUN cmake --build . --target install

RUN mkdir -p /root
USER root
WORKDIR /root
COPY config.ini /root
COPY start.sh /root
RUN winpr-makecert -rdp -path . server
ENTRYPOINT /root/start.sh