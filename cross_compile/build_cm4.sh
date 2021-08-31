#!/usr/bin/env bash

# docker or podman
CONTAINER_BIN=docker

usage() {
    echo "Usage: ./build_cm4.sh (32|64) [-y]"
}

# kernel8 for arm64, kernel7l for 32-bit
ARCH_CHOSEN=0
SKIP_PROMPT=0
ZFS_ONLY=0
for arg in "$@"; do
    case $arg in
        "32")
            [[ $ARCH_CHOSEN != '0' ]] && usage && exit 1
            KERNEL=kernel7l
            ARCH_=arm
            CROSS_COMPILE_=arm-linux-gnueabihf-
            IMAGE_=zImage
            ARCH_CHOSEN=1
            ;;
        "64")
            [[ $ARCH_CHOSEN != '0' ]] && usage && exit 1
            KERNEL=kernel8
            ARCH_=arm64
            CROSS_COMPILE_=aarch64-linux-gnu-
            IMAGE_=Image
            ARCH_CHOSEN=1
            ;;
        "-z")
            ZFS_ONLY=1
            ;;
        "-y")
            SKIP_PROMPT=1
            ;;
        "-h")
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

[[ $ARCH_CHOSEN == 0 ]] && usage && exit 1

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
    --env KERNEL=$KERNEL --env ARCH=$ARCH_ --env CROSS_COMPILE=$CROSS_COMPILE_ --env IMAGE_=$IMAGE_ --env SKIP_PROMPT=$SKIP_PROMPT --env ZFS_ONLY=$ZFS_ONLY \
    -v $(pwd)/..:/root/linux -v $(pwd)/boot:/boot_out -v $(pwd)/rootfs:/rootfs_out -v $(pwd)/configs:/config_out \
    raspberry-pi-crosscompile \
    entrypoint.sh
