#!/usr/bin/env bash

make -j$(nproc) ARCH=$ARCH_ CROSS_COMPILE=$CROSS_COMPILE_ bcm2711_defconfig
[[ "$?" != "0" ]] && exit 1

vim .config

make savedefconfig
[[ "$?" != "0" ]] && exit 1

mv defconfig /config_out

make -j$(nproc) ARCH=$ARCH_ CROSS_COMPILE=$CROSS_COMPILE_ $IMAGE_ modules dtbs
[[ "$?" != "0" ]] && exit 1

env PATH=$PATH make ARCH=$ARCH_ CROSS_COMPILE=$CROSS_COMPILE_ INSTALL_MOD_PATH=/rootfs_out modules_install
[[ "$?" != "0" ]] && exit 1

mkdir -p /boot_out/overlays

cp arch/$ARCH_/boot/$IMAGE_ /boot_out/$KERNEL.img
cp arch/$ARCH_/boot/dts/broadcom/*.dtb /boot_out/
cp arch/$ARCH_/boot/dts/overlays/*.dtb* /boot_out/overlays/
cp arch/$ARCH_/boot/dts/overlays/README /boot_out/overlays/
