#!/usr/bin/env bash

# docker or podman
CONTAINER_BIN=docker

# kernel8 for arm64, kernel7l for 32-bit
if [[ "$1" == "32" ]]; then
    KERNEL=kernel7l
    ARCH_=arm
    CROSS_COMPILE_=arm-linux-gnueabihf-
    IMAGE_=zImage
elif [[ "$1" == "64" ]]; then
    KERNEL=kernel8
    ARCH_=arm64
    CROSS_COMPILE_=aarch64-linux-gnu-
    IMAGE_=Image
else
    echo "Usage: ./build_cm4.sh (32|64)"
    exit 1
fi

command -v $CONTAINER_BIN > /dev/null 2>&1 || {
	echo "Please install $CONTAINER_BIN.";
	exit 1;
}

# if image DNE, build it
if [[ "$($CONTAINER_BIN images -q raspberry-pi-crosscompile 2> /dev/null)" == "" ]]; then
	$CONTAINER_BIN build -t raspberry-pi-crosscompile .
	res=$?
	if [ $res -ne 0 ]; then
		echo "Building $CONTAINER_BIN image failed."
		exit $res
	fi
fi

sudo rm boot/* rootfs/* -rf

$CONTAINER_BIN run -it --rm \
    --env KERNEL=$KERNEL --env ARCH_=$ARCH_ --env CROSS_COMPILE_=$CROSS_COMPILE_ --env IMAGE_=$IMAGE_ \
    -v $(pwd)/..:/root/linux -v $(pwd)/boot:/boot_out -v $(pwd)/rootfs:/rootfs_out -v $(pwd)/configs:/config_out \
    raspberry-pi-crosscompile \
    bash
