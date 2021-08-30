#!/usr/bin/env bash

if [[ "$ZFS_ONLY" == 0 ]]; then
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
    echo "Compiling Kernel..."
    make -j$(nproc) ARCH=$ARCH_ CROSS_COMPILE=$CROSS_COMPILE_ $IMAGE_ modules dtbs headers
    [[ "$?" != "0" ]] && exit 1
    echo

    echo "################################################################"
    echo "Installing Modules to ./rootfs/"
    mkdir -p /rootfs_out/usr
    env PATH=$PATH make ARCH=$ARCH_ CROSS_COMPILE=$CROSS_COMPILE_ INSTALL_MOD_PATH=/rootfs_out/usr INSTALL_HDR_PATH=/rootfs_out/usr modules_install headers_install
    [[ "$?" != "0" ]] && exit 1
    echo

    echo "################################################################"
    echo "Installing Kernel and Overlays to ./boot/"
    mkdir -p /boot_out/overlays
    cp -p arch/$ARCH_/boot/$IMAGE_ /boot_out/$KERNEL.img
    cp -p arch/$ARCH_/boot/dts/broadcom/*.dtb /boot_out/
    cp -p arch/$ARCH_/boot/dts/overlays/*.dtb* /boot_out/overlays/
    cp -p arch/$ARCH_/boot/dts/overlays/README /boot_out/overlays/
    echo
fi

if [[ -f cross_compile/zfs/autogen.sh ]]; then
    echo "################################################################"
    echo "Building ZFS DKMS"
    # mv /usr/include /usr/include.bak
    # ln -snf /usr/${CROSS_COMPILE_ : : -1}/include /usr/include
    # mkdir -p /usr/include/{sys,linux}
    ln -snf /usr/${CROSS_COMPILE_: : -1}/include/asm/byteorder.h /usr/${CROSS_COMPILE_: : -1}/include/sys/byteorder.h
    pushd cross_compile/zfs
    git clean -fX
    # export C_INCLUDE_PATH = /usr/${CROSS_COMPILE_: : -1}/include $(pwd)/include/os/linux/spl/ $C_INCLUDE_PATH
    # ln -snf $(pwd)/include/os/linux/zfs/sys/zfs_context_os.h /usr/include/sys/zfs_context_os.h
    # ln -snf $(pwd)/include/os/linux/kernel/linux/dcache_compat.h /usr/include/linux/dcache_compat.h
    ./autogen.sh
    ./configure --with-linux=$(pwd)/../../ --host=${CROSS_COMPILE_: : -1} --with-sysroot=/usr/${CROSS_COMPILE_: : -1} #CFLAGS="-g -O2 -I./include/os/linux/spl -I./include/os/linux/zfs -I../../include"
    [[ "$?" != "0" ]] && echo ZFS configure failed. && exit 1
    make -j$(nproc) # CFLAGS="-g -O2 -I./include/os/linux/spl -I./include/os/linux/spl -I../../include"
    [[ "$?" != "0" ]] && echo ZFS build failed. && exit 1
    make DESTDIR=/rootfs_out install
    [[ "$?" != "0" ]] && echo ZFS install failed. && exit 1
    popd
    echo
fi

echo "################################################################"
echo "Kernel Compilation Complete."
echo
echo "Copy files from ./rootfs/ to / of the RPI and"
echo "files from ./boot/ to /boot of the RPI."
echo
echo "Also copy the entire kernel source directory to /root/linux on"
echo "the RPI for module compilation, excluding the cross_compilation/"
echo "directory."