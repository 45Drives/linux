FROM debian:latest

RUN apt update -y
RUN apt install -y git bc bison flex libssl-dev make libc6-dev libncurses5-dev \
    crossbuild-essential-armhf crossbuild-essential-arm64 libncurses5-dev vim kmod rsync \
    build-essential autoconf automake libtool gawk alien fakeroot dkms libblkid-dev \
    uuid-dev libudev-dev zlib1g-dev libaio-dev libattr1-dev libelf-dev python3 python3-dev \
    python3-setuptools python3-cffi libffi-dev python3-packaging

RUN mkdir -p /root/linux /boot_out /rootfs_out /config_out

WORKDIR /root/linux

USER root:root

COPY entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/entrypoint.sh