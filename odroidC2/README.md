Inspired in rancherOS build docker system


docker build . -t rancheros-odroidc2 |
&& docker run -i -v $(pwd):/build rancheros-odroidc2 \
&& sudo dd if=u-boot.bin of=/dev/rdisk2 bs=512 seek=97 \
&& sudo sync


fip/fip_create --bl30 fip/gxb/bl30.bin \
               --bl301 fip/gxb/bl301.bin \
               --bl31  fip/gxb/bl31.bin \
               --bl33  u-boot.bin \
               fip.bin

fip/fip_create --dump fip.bin

# http://odroid.com/dokuwiki/doku.php?id=en:c2_building_u-boot

Firmware Image Package ToC:
---------------------------
- SCP Firmware BL3-0: offset=0x4000, size=0x9E88
- SCP Firmware BL3-0-1: offset=0x10000, size=0x1268
- EL3 Runtime Firmware BL3-1: offset=0x14000, size=0x110D0
- Non-Trusted Firmware BL3-3: offset=0x28000, size=0x421A6
---------------------------

cat fip/gxb/bl2.package fip.bin > boot_new.bin

fip/gxb/aml_encrypt_gxb --bootsig \
              --input boot_new.bin \
              --output u-boot.img

dd if=u-boot.img of=u-boot.gxbb bs=512 skip=96


Area Name                | Size       | From(sector #) | To(Sector #)     | Name for Fastboot | Partition Name
------------------------ | ---------- | -------------- | ---------------- | ----------------- | --------------
BL1 / MBR                | 48.5KB     | 0              | 96               | -                 |
U-Boot                   | 667.5KB    | 97             | 1431             | bootloader        |
U-Boot Environment       | 32KB       | 1440           | 1503             | env               |
FAT32 for boot           | 128MB      | 2048           | 264191           | -                 | mmcblk0p1
EXT4 for root filesystem | Up to 64GB | 264192         | remaining blocks | -                 | mmcblk0p2

// HOST
dd if=sd_fuse/bl1.bin.hardkernel of=/dev/rdisk2 conv=fsync bs=1 count=442
dd if=sd_fuse/bl1.bin.hardkernel of=/dev/rdisk2 conv=fsync bs=512 skip=1 seek=1
dd if=u-boot.gxbb of=/dev/rdisk2 conv=fsync bs=512 seek=97
dd if=/dev/zero of=/dev/rdisk2 conv=fsync bs=512 count=512 seek=2048

```shell
cd ${PWD_DIR}
# Create build path
mkdir -p ${DIR_BIN}
# Remove previous image disk
rm -rf ${FILE_DISK}
# Create empty image
dd if=/dev/zero of=${FILE_DISK} bs=516 count=26746880
# Reset MBR (Raises an Error -> sfdisk: BLKRRPART: Inappropriate icoctl for device) // TODO
sudo sfdisk -R ${FILE_DISK}
# Create partition table
cat <<EOT | sudo sfdisk --in-order -L -uM ${FILE_DISK}
1,16,c
,,L
EOT
# Map image partitions
sudo kpartx -a ${FILE_DISK}
# Set format BOOT partition
mkfs.vfat /dev/mapper/loop0p1
# Set format ARCH partition
mkfs.ext4 /dev/mapper/loop0p2
# Create mount point for BOOT
sudo mkdir -p /mnt/boot && sudo mount -o loop,rw,sync /dev/mapper/loop0p1 /mnt/boot
# Create mount point for ARCH
sudo mkdir -p /mnt/arch && sudo mount -o loop,rw,sync /dev/mapper/loop0p2 /mnt/arch
# Copy kernel file to boot partition
sudo cp ${FILE_KERNEL} /mnt/boot/
# Copy script.bin file to boot partition
sudo cp ${FILE_SCRIPT} /mnt/boot/
# Getting archlinux armv7 tarball
wget http://archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz
# Uncompressing tarball file into arch partition
bsdtar -xpf ArchLinuxARM-armv7-latest.tar.gz -C /mnt/arch
# Sync files
sync
```




# Compile GRUB2

git clone git://git.savannah.gnu.org/grub.git
cd grub
./autogen.sh
./configure --with-platform=efi
make



# cat /boot/grub/grub.cfg
# This is a comment
echo "Hello from grub.cfg"

menuentry 'Test menu entry' {
        devicetree /vexpress-v2p-ca9.dtb
        initrd /initrd
        linux /zImage console=ttyAMA0,38400n8 rootwait clcd=xvga mmci.fmax=4000000 root=/dev/mmcblk0p2 ext4 ro
}

grub-mkstandalone -o grub.efi -O arm64-efi


# MAC FOMAT partition
fdisk -e /dev/disk2
erase
edit 1
2048
512 * 512
0B Win95 FAT-32
sudo newfs_msdos -v Name /dev/disk2s1



# http://odroid.com/dokuwiki/doku.php?id=en:c2_building_u-boot
# https://github.com/agraf/u-boot/archive/signed-efi-next.tar.gz

docker build . -t rancheros-odroidc2 && docker run -it -v $(pwd):/src --privileged rancheros-odroidc2 bash

http://chezphil.org/norway/


Booting alternate kernels

http://forum.odroid.com/viewtopic.php?t=20869&p=141225

http://linux-meson.com/doku.php
