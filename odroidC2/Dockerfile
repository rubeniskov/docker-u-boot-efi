FROM aarch64/debian:jessie

ENV DAPPER_RUN_ARGS --privileged
ENV DAPPER_OUTPUT dist
ENV DAPPER_WORKDIR /src
ENV DAPPER_BUILDDIR $DAPPER_WORKDIR/build

WORKDIR /src

# Download dependencies
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl dosfstools tree zip git build-essential gcc libc6 \
    zlib1g wget bc device-tree-compiler libssl-dev autoconf python bison flex qemu-user-static

RUN mkdir -p build
# Initialize BL1 / MBR U-Boot and U-Boot Enviroment image space 2048KB
RUN dd if=/dev/zero of=build/mbr.iso conv=sync,noerror bs=512 count=2048 \
    && echo "2048,262144,c" | sfdisk -L -S 32 -H 64 --quiet --unit S --force --in-order build/mbr.iso > /dev/null 2>&1

# Initialize boot image space partition 128MB
RUN dd if=/dev/zero of=build/boot.iso conv=sync,noerror bs=512 count=262144 \
    && mkfs.vfat build/boot.iso

# Compose iso image
RUN cat build/mbr.iso build/boot.iso > build/image.iso && rm build/mbr.iso build/boot.iso \
    && sfdisk --dump build/image.iso

# Compile U-Boot
RUN wget -qO- https://github.com/agraf/u-boot/archive/efi-next.tar.gz | tar xzv \
    && cd u-boot-efi-next \
    && make odroid-c2_defconfig \
    && make -j4$(nproc) \
    && cp u-boot.bin $DAPPER_WORKDIR/build/u-boot.bin

# Compile amlogic firmware tools and trust certificates
# check https://github.com/ARM-software/arm-trusted-firmware/blob/master/docs/firmware-design.md
RUN REPO=u-boot BRANCH=odroidc2-v2015.01 TARGET=u-boot-odroidc2 \
    && mkdir -p $TARGET \
    && wget -qO- https://github.com/hardkernel/$REPO/archive/$BRANCH.tar.gz \
      | tar xzv --strip-components 1 -C $TARGET \
                  $REPO-$BRANCH/tools/fip_create \
                  $REPO-$BRANCH/fip \
                  $REPO-$BRANCH/sd_fuse \
    && cp $DAPPER_WORKDIR/$TARGET/sd_fuse/bl1.bin.hardkernel $DAPPER_WORKDIR/build/bl1.bin.hardkernel \
    && cd $DAPPER_WORKDIR/$TARGET/tools/fip_create \
    && make \
    && chmod 755 fip_create \
    && ln -s $(pwd)/fip_create /usr/local/bin/ \
    && cd $DAPPER_WORKDIR/$TARGET/fip/gxb \
    && fip_create --bl30 bl30.bin \
                  --bl301 bl301.bin \
                  --bl31 bl31.bin \
                  --bl33 $DAPPER_WORKDIR/build/u-boot.bin \
                   $DAPPER_WORKDIR/build/u-boot-fip.bin \
    && fip_create --dump $DAPPER_WORKDIR/build/u-boot-fip.bin \
    && cat bl2.package $DAPPER_WORKDIR/build/u-boot-fip.bin > $DAPPER_WORKDIR/build/u-boot-bl2.bin \
    && ./aml_encrypt_gxb --bootsig --input $DAPPER_WORKDIR/build/u-boot-bl2.bin --output $DAPPER_WORKDIR/build/u-boot-gxb.bin \
    && dd if=$DAPPER_WORKDIR/build/u-boot-gxb.bin of=$DAPPER_WORKDIR/build/u-boot-gxbb.bin bs=512 skip=96

#./aml_encrypt_gxb_n ../dist/u-boot-bl2.bin ../build/u-boot-gxb.bin

# Write U-Boot Trusted into ISO image
RUN cd $DAPPER_WORKDIR/build \
    && dd if=bl1.bin.hardkernel of=image.iso conv=notrunc,fsync bs=1 count=442 \
    && dd if=bl1.bin.hardkernel of=image.iso conv=notrunc,fsync bs=512 skip=1 seek=1 \
    && dd if=u-boot-gxbb.bin of=image.iso conv=notrunc,fsync bs=512 seek=97

# RUN cd /src && git clone https://github.com/agraf/u-boot.git -b efi-next
# RUN cd /src && git clone https://github.com/hardkernel/u-boot_firmware.git -b odroidc2-bl301
#
# RUN cd u-boot \
#     && git remote add u-boot_firmware ../u-boot_firmware/ \
#     && git fetch u-boot_firmware \
#     && git merge --no-commit u-boot_firmware/odroidc2-bl301 \
#     && make distclean \
#     && make odroid-c2_defconfig \
#     && make -j4$(nproc)


# RUN cd /src && git clone https://github.com/ARM-software/arm-trusted-firmware.git
# RUN cd arm-trusted-firmware && make PLAT=fvp BL33=../u-boot/u-boot.bin fip
#
# RUN cd arm-trusted-firmware \
#     && wget -qO- https://github.com/hardkernel/u-boot/archive/s905_5.1.1_v3.0.tar.gz | tar xzv u-boot-s905_5.1.1_v3.0/fip u-boot-s905_5.1.1_v3.0/sd_fuse \
#     && tools/fiptool/fiptool create \
#                   --scp-fw  u-boot-s905_5.1.1_v3.0/fip/gxb/bl30.bin \
#                   --scp-fw-cert u-boot-s905_5.1.1_v3.0/fip/gxb/bl301.bin \
#                   --soc-fw  u-boot-s905_5.1.1_v3.0/fip/gxb/bl31.bin \
#                   --nt-fw ../u-boot/u-boot.bin \
#                   fip.bin \
#     && tools/fiptool/fiptool info fip.bin \
#     && cat u-boot-s905_5.1.1_v3.0/fip/gxb/bl2.package fip.bin > u-boot.bin \
#     && u-boot-s905_5.1.1_v3.0/fip/gxb/aml_encrypt_gxb --bootsig --input u-boot.bin --output u-boot.img \
#     && dd if=u-boot.img of=u-boot.gxbb bs=512 skip=96

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

ADD scripts /src/scripts/

CMD ["./scripts/build.sh"]
