# Storinator JR Kernel
## Cross Compilation Steps
### Prerequisites
You must have docker or podman installed. If you want to use podman, edit cross_compile/build_cm4.sh and change `CONTAINER_BIN=docker` to `CONTAINER_BIN=podman`.
### Compiling
```bash
git clone https://github.com/45Drives/linux.git
cd linux
git submodule update --init # run if you want zfs module
cd cross_compile
./build_cm4 64 -y # omit -y if you want to customize config
```
### Installing
Once compilation is complete, the files are installed to `cross_compile/rootfs/` and `cross_compile/boot/`.
Copy files from `rootfs/` into the root partition of the Pi and files from `boot/` into the boot partition.

Linux kernel
============

There are several guides for kernel developers and users. These guides can
be rendered in a number of formats, like HTML and PDF. Please read
Documentation/admin-guide/README.rst first.

In order to build the documentation, use ``make htmldocs`` or
``make pdfdocs``.  The formatted documentation can also be read online at:

    https://www.kernel.org/doc/html/latest/

There are various text files in the Documentation/ subdirectory,
several of them using the Restructured Text markup notation.

Please read the Documentation/process/changes.rst file, as it contains the
requirements for building and running the kernel, and information about
the problems which may result by upgrading your kernel.
