#!/bin/bash
set -e

################################################################################
# Please modify
LIBREELEC_PLATFORM="LibreELEC-Odroid_C2.aarch64-7.1.0"
# LIBREELEC_BUILD_DIR="/home/aNORes/build/LibreELEC.tv.7.0"
LIBREELEC_BUILD_DIR=""
LIBREELEC_BUILD_DIR_LINUX="linux-9391ca5"
################################################################################

if [ -z "$LIBREELEC_BUILD_DIR" ]; then
    echo -e "\n\e[92mPlease modify variables:\nLIBREELEC_PLATFORM, LIBREELEC_BUILD_DIR, LIBREELEC_BUILD_DIR_LINUX in this script.\e[0m\n"
    exit
fi

LIBREELEC_BUILD_DIR="$LIBREELEC_BUILD_DIR/build.$LIBREELEC_PLATFORM"
LIBREELEC_BUILD_KERNEL_VER="$(cat $LIBREELEC_BUILD_DIR/$LIBREELEC_BUILD_DIR_LINUX/include/config/kernel.release)"

git clone git://linuxtv.org/media_build.git
cd media_build
git checkout aac60f8
wget http://linuxtv.org/downloads/drivers/linux-media-2016-08-08-b6aa39228966.tar.bz2 -O linux/linux-media.tar.bz2
wget http://linuxtv.org/downloads/drivers/linux-media-2016-08-08-b6aa39228966.tar.bz2.md5 -O linux/linux-media.tar.bz2.md5
make -C linux/ untar
patch -p1 < ../patches/media_build-2016-08-08-b6aa39228966-changes-for-libreelec-odroidc2.patch
ARCH=arm64 CROSS_COMPILE=$LIBREELEC_BUILD_DIR/toolchain/bin/aarch64-libreelec-linux-gnueabi- DIR=$LIBREELEC_BUILD_DIR/$LIBREELEC_BUILD_DIR_LINUX make release
make stagingconfig
################################################################################
# disable Remote Controller support
# make menuconfig
#	Multimedia support  --->
#		Remote Controller support = n
# save .config
# i prepared this
################################################################################
cp -f ../configs/media_build-2016-08-08-b6aa39228966-changes-for-libreelec-odroidc2.config v4l/.config
make -j8
################################################################################
# repack LibreELEC SYSTEM image and install media_build
################################################################################
tar xvf $LIBREELEC_BUILD_DIR/../target/$LIBREELEC_PLATFORM.tar
mkdir -p ./SYSTEM-squashfs ./SYSTEM-new
sudo mount -t squashfs -o loop $LIBREELEC_PLATFORM/target/SYSTEM ./SYSTEM-squashfs
sudo cp -av ./SYSTEM-squashfs/* ./SYSTEM-new
sudo umount ./SYSTEM-squashfs
sudo cp -av "./SYSTEM-new/lib/modules/$LIBREELEC_BUILD_KERNEL_VER" "./SYSTEM-new/lib/modules/$LIBREELEC_BUILD_KERNEL_VER-orig"
sudo cp -av "./SYSTEM-new/lib/firmware" "./SYSTEM-new/lib/firmware-$LIBREELEC_BUILD_KERNEL_VER-media_build"
sudo mount --bind "./SYSTEM-new/lib/modules" /lib/modules
sudo mount --bind "./SYSTEM-new/lib/firmware-$LIBREELEC_BUILD_KERNEL_VER-media_build" /lib/firmware
# path to correct strip binary
PATH=$LIBREELEC_BUILD_DIR/toolchain/aarch64-libreelec-linux-gnueabi/bin/:$PATH
sudo "PATH=$PATH" make install
sudo umount /lib/modules
sudo umount /lib/firmware
sudo mv "./SYSTEM-new/lib/modules/$LIBREELEC_BUILD_KERNEL_VER" "./SYSTEM-new/lib/modules/$LIBREELEC_BUILD_KERNEL_VER-media_build"
sudo mv "./SYSTEM-new/lib/modules/$LIBREELEC_BUILD_KERNEL_VER-orig" "./SYSTEM-new/lib/modules/$LIBREELEC_BUILD_KERNEL_VER"
rm $LIBREELEC_PLATFORM/target/SYSTEM
rm $LIBREELEC_PLATFORM/target/SYSTEM.md5
sudo $LIBREELEC_BUILD_DIR/toolchain/bin/mksquashfs ./SYSTEM-new $LIBREELEC_PLATFORM/target/SYSTEM -noappend -comp lzo
cd $LIBREELEC_PLATFORM ; md5sum -t target/SYSTEM > target/SYSTEM.md5 ; cd ..
tar cvf $LIBREELEC_BUILD_DIR/../target/$LIBREELEC_PLATFORM-media_build.tar $LIBREELEC_PLATFORM
# cleanup
sudo rm -rf SYSTEM-new SYSTEM-squashfs $LIBREELEC_PLATFORM
echo -e "\nNew repack file: $LIBREELEC_PLATFORM-media_build.tar in target directory"
echo -e "\n\e[92mAfter first boot LibreELEC please do:\necho \"$LIBREELEC_BUILD_KERNEL_VER-media_build\" > /storage/downloads/dvb-drivers.txt\e[0m\n"
