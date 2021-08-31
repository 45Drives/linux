#!/usr/bin/env bash

BUILD_ZFS=$([[ -f cross_compile/zfs/autogen.sh ]] && echo 1 || echo 0)

if [[ "$ZFS_ONLY" != "1" ]]; then
    make distclean

    echo "################################################################"
    echo "Generating default config..."
    make -j$(nproc) bcm2711_defconfig
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
    make -j$(nproc) prepare scripts
    echo

    echo "################################################################"
    echo "Compiling Kernel..."
    make -j$(nproc) $IMAGE_ modules dtbs headers
    [[ "$?" != "0" ]] && exit 1
    echo
fi

if [[ $BUILD_ZFS ]] && [[ "$ARCH" != "arm" ]]; then
    echo "################################################################"
    echo "Configuring ZFS"
    pushd cross_compile/zfs
    git clean -fX
    git reset HEAD --hard
    sh autogen.sh
    ./configure --with-linux=/root/linux --with-linux-obj=/root/linux --host=${CROSS_COMPILE: : -1}
    [[ "$?" != "0" ]] && echo ZFS configure failed. && exit 1
    echo
    echo "################################################################"
    echo "Building ZFS"
    make -j$(nproc)
    [[ "$?" != "0" ]] && echo ZFS build failed. && exit 1
    echo
    echo "################################################################"
    echo "Installing ZFS to cross_compile/rootfs/"
    make DESTDIR=/rootfs_out install
    [[ "$?" != "0" ]] && echo ZFS install failed. && exit 1
    popd
    echo
elif [[ $BUILD_ZFS ]]; then
    echo "################################################################"
    echo "Cannot build ZFS for 32 bit kernel. Skipping."
    echo
fi

if [[ "$ZFS_ONLY" != "1" ]]; then
    echo "################################################################"
    echo "Installing Modules to ./rootfs/"
    mkdir -p /rootfs_out/usr
    env PATH=$PATH make INSTALL_MOD_PATH=/rootfs_out/usr INSTALL_HDR_PATH=/rootfs_out/usr modules_install headers_install
    [[ "$?" != "0" ]] && exit 1
    echo

    echo "################################################################"
    echo "Installing Kernel and Overlays to ./boot/"
    mkdir -p /boot_out/overlays
    cp -p arch/$ARCH/boot/$IMAGE_ /boot_out/$KERNEL.img
    cp -p arch/$ARCH/boot/dts/broadcom/*.dtb /boot_out/
    cp -p arch/$ARCH/boot/dts/overlays/*.dtb* /boot_out/overlays/
    cp -p arch/$ARCH/boot/dts/overlays/README /boot_out/overlays/
    echo
fi

echo "################################################################"
echo "Kernel Compilation Complete."
echo
echo "Copy files from ./rootfs/ to / of the RPI and"
echo "files from ./boot/ to /boot of the RPI."
echo
