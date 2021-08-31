FROM debian:latest

RUN dpkg --add-architecture arm64
RUN dpkg --add-architecture armhf

RUN apt update -y
RUN apt install -y git bc bison flex libssl-dev make libc6-dev libncurses5-dev \
    crossbuild-essential-armhf crossbuild-essential-arm64 libncurses5-dev vim kmod rsync \
    build-essential autoconf automake libtool gawk alien fakeroot dkms \
    libblkid-dev:arm64 uuid-dev:arm64 libudev-dev:arm64 zlib1g-dev:arm64 libaio-dev:arm64 libattr1-dev:arm64 libelf-dev:arm64 libssl-dev:arm64 libpython3.7-dev:arm64 libpam0g-dev:arm64 \
    python3 python3-dev python3-setuptools python3-cffi libffi-dev python3-packaging

RUN mkdir -p /root/linux /boot_out /rootfs_out /config_out

WORKDIR /root/linux

USER root:root

COPY entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/entrypoint.sh