FROM aarch64/debian:jessie

ENV DAPPER_RUN_ARGS --privileged
ENV DAPPER_OUTPUT dist

WORKDIR /src

# Download dependencies
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl dosfstools tree zip git build-essential gcc libc6 zlib1g wget bc device-tree-compiler libssl-dev autoconf python bison flex kpartx

RUN mkdir -p build
# Initialize BL1 / MBR U-Boot and U-Boot Enviroment 2048KB
RUN dd if=/dev/zero of=build/image.iso bs=512 count=2048
# Initialize boot partition 128MB
RUN dd if=/dev/zero of=build/image.iso bs=512 count=262144 seek=2048

RUN sfdisk -R build/image.iso && echo -e '2,127,c\n,,L' | sfdisk --quiet --in-order --force -L --unit M build/image.iso

RUN kpartx -a build/image.iso

# Set format BOOT partition
#mkfs.vfat /dev/mapper/loop0p1
#
# Unsupported ioctl: cmd=0xffffffff80200204
# # partition table of /build/test.img
# unit: sectors
#
# /build/test.img1 : start=     2048, size=   262144, Id= c, bootable
# /build/test.img2 : start=   264192, size=123727872, Id=83
# /build/test.img3 : start=        0, size=        0, Id= 0
# /build/test.img4 : start=        0, size=        0, Id= 0
#
# RUN losetup /dev/loop0 build/image.iso

# Compile U-Boot
RUN git config --global user.email "custom@compile.com" \
    && git config --global user.name "custom.compile"

RUN cd /src && git clone https://github.com/agraf/u-boot.git -b efi-next
RUN cd /src && git clone https://github.com/hardkernel/u-boot_firmware.git -b odroidc2-bl301

RUN cd u-boot \
    && git remote add u-boot_firmware ../u-boot_firmware/ \
    && git fetch u-boot_firmware \
    && git merge --no-commit u-boot_firmware/odroidc2-bl301 \
    && make distclean \
    && make odroid-c2_defconfig \
    && make -j4$(nproc)

RUN cd /src && git clone https://github.com/ARM-software/arm-trusted-firmware.git
RUN cd arm-trusted-firmware && make PLAT=fvp BL33=../u-boot/u-boot.bin fip

RUN cd arm-trusted-firmware \
    && wget -qO- https://github.com/hardkernel/u-boot/archive/s905_5.1.1_v3.0.tar.gz | tar xzv u-boot-s905_5.1.1_v3.0/fip u-boot-s905_5.1.1_v3.0/sd_fuse \
    && tools/fiptool/fiptool create \
                  --scp-fw  u-boot-s905_5.1.1_v3.0/fip/gxb/bl30.bin \
                  --scp-fw-cert u-boot-s905_5.1.1_v3.0/fip/gxb/bl301.bin \
                  --soc-fw  u-boot-s905_5.1.1_v3.0/fip/gxb/bl31.bin \
                  --nt-fw ../u-boot/u-boot.bin \
                  fip.bin \
    && tools/fiptool/fiptool info fip.bin \
    && cat u-boot-s905_5.1.1_v3.0/fip/gxb/bl2.package fip.bin > u-boot.bin \
    && u-boot-s905_5.1.1_v3.0/fip/gxb/aml_encrypt_gxb --bootsig --input u-boot.bin --output u-boot.img \
    && dd if=u-boot.img of=u-boot.gxbb bs=512 skip=96

# dd if=sd_fuse/bl1.bin.hardkernel of=/dev/rdisk2 conv=fsync bs=1 count=442
# dd if=sd_fuse/bl1.bin.hardkernel of=/dev/rdisk2 conv=fsync bs=512 skip=1 seek=1
# dd if=u-boot.gxbb of=/dev/rdisk2 conv=fsync bs=512 seek=97
# dd if=/dev/zero of=/dev/rdisk2 conv=fsync bs=512 count=512 seek=2048

# Compile Kernel
# RUN cd /src && git clone -c http.sslVerify=false --depth 1 https://github.com/hardkernel/linux.git -b odroidc2-3.14.y
# RUN cd linux && make odroidc2_defconfig && make -j4$(nproc) Image dtbs modules

# Build RancherOS
# RUN cd /src && git clone -c http.sslVerify=false --depth 1 https://github.com/rancher/os.git -b master
# gzip -c ~/file-inird > initrd-<kernel-version>
# mkinitrd /boot/initrd-2.0.36-3.img 2.0.36-3
# cp /usr/src/linux/arch/i386/boot/bzImage vmlinuz-2.0.36
# RUN curl -fL https://releases.rancher.com/os/latest/rootfs_arm64.tar.gz > /src/assets/rootfs_arm64.tar.gz
#RUN /src/assets/kernel.deb
#RUN /src/assets/bootloader.deb

CMD cp /src/arm-trusted-firmware/u-boot.bin /build/u-boot.bin
