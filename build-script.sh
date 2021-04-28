#!/bin/sh

echo "Running image setup..."

# === check for arguments ===
echo "Checking user arguments..."
if [ -z "$1" ]; then
  echo -e "Error: Mount point unspecified!\nPlease include path to temporarily mount .img file to."
  exit
fi

cleanup(){
    set +e # all commands in this function should run even with errors
    # unmount
    echo "Unmounting..."
    umount $1/boot 2> /dev/null
    umount $1/linux 2> /dev/null
}

# === check for root priveledges ===
echo "Checking for root priveledges..."
if [[ $EUID -ne 0 ]]; then
  echo -e "Error: No root priveledge detected!\nPlease run with 'sudo'"
  exit
fi

# === check to make sure various files exist ===
imgfilename="de10_nano_linux_console.img"
imgfile="img_src/$imgfilename"
echo "Checking for $imgfilename in img_src/"
if [ ! -f $imgfile ]; then
  echo -e "Error: $imgfile not found!\nPlease copy/move $imgfilename to img_src/"
  exit
fi
echo "Image found."

# === make sure nothing is mounted in specified mount directory yet ===
echo -e "Checking mount directory $1 for existing mount..."
mkdir -p $1/linux
mkdir -p $1/boot
if $(findmnt -rn -o TARGET $1/linux >/dev/null); then
  echo -e "Error: There is already something mounted in $1\nPlease unmount it before re-running\
    build-script.sh"
  exit
fi
if $(findmnt -rn -o TARGET $1/boot >/dev/null); then
  echo -e "Error: There is already something mounted in $1\nPlease unmount it before re-running\
    build-script.sh"
  exit
fi

# === mount the image file ===
echo -e "Preparing mount..."
sectorsize=$(fdisk -l $imgfile\
  | grep -o "Sector size (logical/physical): [0-9]* bytes / [0-9]* bytes"\
  | grep -o "[0-9]*"\
  | head -1)
echo "- Image sector size: $sectorsize B"

bootstart=$(fdisk -lo START,TYPE $imgfile\
  | sed -n "s/W95 FAT32//p"\
  | grep -o "[0-9]*")
echo "- Boot partition start: $bootstart"

bootsectors=$(fdisk -lo SECTORS,TYPE $imgfile\
  | sed -n "s/W95 FAT32//p"\
  | grep -o "[0-9]*")
echo "- Boot partition sector count: $bootsectors"

bootoffset=$((bootstart * sectorsize))
echo "- Boot partition offset: $bootoffset B"

bootsize=$((bootsectors * sectorsize))
echo "- Boot partition size: $bootsize B"

linuxstart=$(fdisk -lo START,TYPE $imgfile\
  | sed -n "s/Linux$//p"\
  | grep -o "[0-9]*")
echo "- Linux partition start: $linuxstart"

linuxsectors=$(fdisk -lo SECTORS,TYPE $imgfile\
  | sed -n "s/Linux//p"\
  | grep -o "[0-9]*")
echo "- Linux partition sector count: $linuxsectors"

linuxoffset=$((linuxstart * sectorsize))
echo "- Linux partition offset: $linuxstart B"

linuxsize=$((linuxsectors * sectorsize))
echo "- Linux partition size: $bootsize B"

trap 'cleanup $1' EXIT
set -e # the below commands should exit on fail

echo "Mounting linux partition..."
mount -t ext4 -o loop,offset=$linuxoffset,sizelimit=$linuxsize $imgfile $1/linux

echo "Mounting boot partition..."
mount -t vfat -o loop,offset=$bootoffset,sizelimit=$bootsize $imgfile $1/boot

# === install boot files ===
echo "Installing boot files..."
cp fpgame/soc_system.rbf $1/boot/
cp linux-socfpga/arch/arm/boot/zImage $1/boot/
cp linux-socfpga/arch/arm/boot/dts/fpgame_int.dtb $1/boot/socfpga.dtb

echo "Installing Linux files..."
#Copy over kernel modules and write /etc/modules
echo -e "apu\ncon\nppu" > $1/linux/etc/modules-load.d/fp_game.conf
mkdir -p $1/linux/lib/modules/5.9.0/
cp Kernel/apu/apu.ko $1/linux/lib/modules/5.9.0/
cp Kernel/con/con.ko $1/linux/lib/modules/5.9.0/
cp Kernel/ppu/ppu.ko $1/linux/lib/modules/5.9.0/
# The following is the result of the `depmod` command run manually:
cp Kernel/depmod/modules.dep.bin $1/linux/lib/modules/5.9.0/

set +e # the above commands should exit on fail

echo "build-script.sh completed successfully!"
