FROM debian:latest

RUN apt update -y
RUN apt install -y git bc bison flex libssl-dev make libc6-dev libncurses5-dev crossbuild-essential-armhf crossbuild-essential-arm64 libncurses5-dev vim kmod rsync

RUN mkdir -p /root/linux /boot_out /rootfs_out /config_out

WORKDIR /root/linux

USER root:root

COPY entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/entrypoint.sh