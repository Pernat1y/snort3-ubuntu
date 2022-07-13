#!/bin/bash

# More up-to-date version of https://www.snort.org/documents/snort-3-1-17-0-on-ubuntu-18-20
# Tested on Ubuntu 18.04 LTS and 20.04 LTS
# Build on 22.04 LTS fails - see https://github.com/intel/hyperscan/issues/344 


# Install dependencies
apt-get install -y build-essential autotools-dev libdumbnet-dev libluajit-5.1-dev \
  libpcap-dev zlib1g-dev pkg-config libhwloc-dev cmake liblzma-dev openssl libssl-dev \
  cpputest libsqlite3-dev libtool uuid-dev git autoconf bison flex libcmocka-dev \
  libnetfilter-queue-dev libunwind-dev libmnl-dev ethtool


rm -rf ~/snort_src 2>/dev/null
mkdir ~/snort_src


set -e
set -x


# Build dependencies - libsafec
cd ~/snort_src && \
git clone https://github.com/rurban/safeclib/ && \
cd safeclib && \
./build-aux/autogen.sh && \
./configure && \
make && \
make install


# Build dependencies - pcre
cd ~/snort_src/ && \
wget https://sourceforge.net/projects/pcre/files/pcre/8.45/pcre-8.45.tar.gz && \
tar -xzvf pcre-8.45.tar.gz && \
cd pcre-8.45 && \
./configure && \
make && \
make install


# Build dependencies - gperftools
cd ~/snort_src && \
wget https://github.com/gperftools/gperftools/releases/download/gperftools-2.10/gperftools-2.10.tar.gz && \
tar xzvf gperftools-2.10.tar.gz && \
cd gperftools-2.10 && \
./configure && \
make && \
make install


# Build dependencies - ragel
cd ~/snort_src && \
wget http://www.colm.net/files/ragel/ragel-6.10.tar.gz && \
tar -xzvf ragel-6.10.tar.gz && \
cd ragel-6.10 && \
./configure && \
make && \
make install


# Build dependencies - boost
cd ~/snort_src && \
wget https://boostorg.jfrog.io/artifactory/main/release/1.79.0/source/boost_1_79_0.tar.gz && \
tar -xvzf boost_1_79_0.tar.gz


# Build dependencies - hyperscan
cd ~/snort_src && \
wget https://github.com/intel/hyperscan/archive/refs/tags/v5.4.0.tar.gz && \
tar -xvzf v5.4.0.tar.gz && \
mkdir ~/snort_src/hyperscan-5.4.0-build && \
cd hyperscan-5.4.0-build/ && \
cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DBOOST_ROOT=~/snort_src/boost_1_79_0/ ../hyperscan-5.4.0 && \
make && \
make install


# Build dependencies - flatbuffers
cd ~/snort_src && \
wget https://github.com/google/flatbuffers/archive/refs/tags/v2.0.0.tar.gz -O flatbuffers-v2.0.0.tar.gz && \
tar -xzvf flatbuffers-v2.0.0.tar.gz && \
mkdir flatbuffers-build && \
cd flatbuffers-build && \
cmake ../flatbuffers-2.0.0 && \
make && \
make install


# Build dependencies - libdaq
cd ~/snort_src && \
wget https://github.com/snort3/libdaq/archive/refs/tags/v3.0.8.tar.gz -O libdaq-3.0.8.tar.gz && \
tar -xzvf libdaq-3.0.8.tar.gz && \
cd libdaq-3.0.8 && \
./bootstrap && \
./configure && \
make && \
make install


# Update shared libraries
ldconfig


# Build Snort
cd ~/snort_src && \
wget https://github.com/snort3/snort3/archive/refs/tags/3.1.32.0.tar.gz -O snort3-3.1.32.0.tar.gz && \
tar -xzvf snort3-3.1.32.0.tar.gz && \
cd snort3-3.1.32.0 && \
./configure_cmake.sh --prefix=/usr/local --enable-tcmalloc && \
cd build && \
make && \
make install


# Build Snort extra
cd ~/snort_src && \
wget https://github.com/snort3/snort3_extra/archive/refs/tags/3.1.32.0.tar.gz -O snort3_extra-3.1.32.0.tar.gz && \
tar -xzvf snort3_extra-3.1.32.0.tar.gz && \
cd snort3_extra-3.1.32.0 && \
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/ && \
./configure_cmake.sh --prefix=/usr/local && \
cd build && \
make && \
make install


# Create init script
echo '[Unit]
Description=Snort3 NIDS Daemon
After=syslog.target network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/snort -c /usr/local/etc/snort/snort.lua -s 65535 \
-k none -l /var/log/snort -D -u snort -g snort -i enp0s3 -m 0x1b --create-pidfile \
--plugin-path=/usr/local/lib/snort/plugins/extra

[Install]
WantedBy=multi-user.target
' > /lib/systemd/system/snort3.service && \
systemctl daemon-reload


# Package files to move to a different system
cd / && \
tar -cvf snort3-3.1.17.0.tar \
         /usr/local/bin/snort \
         /usr/local/bin/appid_detector_builder.sh \
         /usr/local/bin/u2boat \
         /usr/local/bin/u2spewfoo \
         /usr/local/bin/snort2lua \
         /usr/local/etc/snort \
         /usr/local/lib/snort \
         /usr/local/share/doc/snort \
         /lib/systemd/system/snort3.service \
	 /usr/lib/x86_64-linux-gnu/libdumbnet.so.1 \
         /usr/lib/x86_64-linux-gnu/libdumbnet.so \
         /usr/lib/x86_64-linux-gnu/libdumbnet.so.1.0.1 \
         /usr/lib/x86_64-linux-gnu/libhwloc.so \
         /usr/lib/x86_64-linux-gnu/libhwloc.so.15 \
         /usr/lib/x86_64-linux-gnu/libhwloc.so.15.1.0 \
         /usr/lib/x86_64-linux-gnu/libpcre.so.3 \
         /usr/lib/x86_64-linux-gnu/libpcre.so.3.13.3 \
         /usr/local/lib/libpcre.so \
         /usr/local/lib/libpcre.so.1 \
         /usr/local/lib/libpcre.so.1.2.13 \
         /usr/local/lib/libsafec.so \
         /usr/local/lib/libsafec.so.3 \
         /usr/local/lib/libtcmalloc.so.4 \
         /usr/local/lib/libtcmalloc.so \
         /usr/local/lib/libtcmalloc.so.4.5.10 && \
gzip snort3-3.1.17.0.tar


# Check installation
/usr/local/bin/snort -V


