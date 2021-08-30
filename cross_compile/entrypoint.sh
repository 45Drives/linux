#!/usr/bin/env bash

BUILD_ZFS=$([[ -f cross_compile/zfs/autogen.sh ]] && echo 1 || echo 0)

make distclean

echo "################################################################"
echo "Generating default config..."
make -j$(nproc) ARCH=$ARCH_ CROSS_COMPILE=$CROSS_COMPILE_ bcm2711_defconfig
[[ "$?" != "0" ]] && exit 1

[[ "$SKIP_PROMPT" == "0" ]] && read -p "Customize config? [y/N]: " RESP || RESP=N
if [[ "$RESP" =~ ^[yY]([eE][sS])?$ ]]; then

    vim .config

    make savedefconfig
    [[ "$?" != "0" ]] && exit 1

    mv defconfig /config_out
    echo "New defconfig in ./config_out/"
    echo
fi

echo "################################################################"
echo "Initializing kernel for building"
make -j$(nproc) ARCH=$ARCH_ CROSS_COMPILE=$CROSS_COMPILE_ prepare scripts modules_prepare
echo

if [[ $BUILD_ZFS ]]; then
    echo "################################################################"
    echo "Building ZFS"
    pushd cross_compile/zfs
    git clean -fX
    git reset HEAD --hard
    git apply ../zfs_config_kernel.patch
    sh autogen.sh
    ./configure --with-linux=/root/linux --with-linux-obj=/root/linux --host=${CROSS_COMPILE_: : -1} --enable-linux-builtin=yes --with-config=kernel
    # ./configure --prefix=/ --libdir=/usr/lib/${CROSS_COMPILE_: : -1} \
    #     --includedir=/usr/include/${CROSS_COMPILE_: : -1} --dataroot=/usr/${CROSS_COMPILE_: : -1}/share \
    #     --enable-linux-builtin=yes --with-linux=/root/linux --with-linux-obj=/root/linux \
    #     --host=${CROSS_COMPILE_: : -1}
    [[ "$?" != "0" ]] && echo ZFS configure failed. && exit 1
    ./copy-builtin /root/linux
    make ARCH=$ARCH_ CROSS_COMPILE=$CROSS_COMPILE_ -j$(nproc)
    [[ "$?" != "0" ]] && echo ZFS build failed. && exit 1
    make install
    [[ "$?" != "0" ]] && echo ZFS install failed. && exit 1
    popd
    echo CONFIG_ZFS=Y >> ./config
    echo
fi

echo "################################################################"
echo "Compiling Kernel..."
make -j$(nproc) ARCH=$ARCH_ CROSS_COMPILE=$CROSS_COMPILE_ deb-pkg # $IMAGE_ modules dtbs headers
[[ "$?" != "0" ]] && exit 1
mv /root/*.deb cross_compile/
echo

# echo "################################################################"
# echo "Installing Modules to ./rootfs/"
# mkdir -p /rootfs_out/usr
# env PATH=$PATH make ARCH=$ARCH_ CROSS_COMPILE=$CROSS_COMPILE_ INSTALL_MOD_PATH=/rootfs_out/usr INSTALL_HDR_PATH=/rootfs_out/usr modules_install headers_install
# [[ "$?" != "0" ]] && exit 1
# echo

# echo "################################################################"
# echo "Installing Kernel and Overlays to ./boot/"
# mkdir -p /boot_out/overlays
# cp -p arch/$ARCH_/boot/$IMAGE_ /boot_out/$KERNEL.img
# cp -p arch/$ARCH_/boot/dts/broadcom/*.dtb /boot_out/
# cp -p arch/$ARCH_/boot/dts/overlays/*.dtb* /boot_out/overlays/
# cp -p arch/$ARCH_/boot/dts/overlays/README /boot_out/overlays/
# echo

echo "################################################################"
echo "Kernel Compilation Complete."
echo
echo "Copy files from ./rootfs/ to / of the RPI and"
echo "files from ./boot/ to /boot of the RPI."
echo
echo "Also copy the entire kernel source directory to /root/linux on"
echo "the RPI for module compilation, excluding the cross_compilation/"
echo "directory."