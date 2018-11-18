#!/bin/sh
#supports_backup in PINN

set -ex

if [ -z "$part1" ] || [ -z "$part2" ]; then
  printf "Error: missing environment variable part1 or part2\n" 1>&2
  exit 1
fi

p1=`echo ${part1} | sed -e 's/dev/dev\/block/g'`
p2=`echo ${part2} | sed -e 's/dev/dev\/block/g'`
p3=`echo ${part3} | sed -e 's/dev/dev\/block/g'`
p4=`echo ${part4} | sed -e 's/dev/dev\/block/g'`

mkdir -p /tmp/1 /tmp/2 /tmp/3 /tmp/4

mount "$part1" /tmp/1
mount "$part2" /tmp/2
mount "$part3" /tmp/3
mount "$part4" /tmp/4

#-----------------------------
convert_image()
{
    file=$1
    cd /tmp/1 #boot
    tail -c+65 <$file.uimg >/tmp/4/$file.cpio.gz
    cd /tmp/4
    gunzip $file.cpio.gz
    mkdir /tmp/4/tmp
    cd tmp
    cpio -i -F ../$file.cpio

    sed fstab.rpi3 -i -e "s|^[^#]/dev.* /boot   |$p1  /boot |"
    sed fstab.rpi3 -i -e "s|^[^#]/dev.* /system |$p2  /system |"
    sed fstab.rpi3 -i -e "s|^[^#]/dev.* /oem    |$p3  /oem |"
    sed fstab.rpi3 -i -e "s|^[^#]/dev.* /data   |$p4  /data |"

    cpio -i -t -F ../$file.cpio | cpio -o -H newc >../${file}_new.cpio
    cd ..
    rm $file.cpio
    mv ${file}_new.cpio $file.cpio
    gzip $file.cpio
    mv $file.cpio.gz /tmp/1/$file.img
    rm -rf /tmp/4/tmp
}
#-----------------------------

if [ -z $restore ]; then
  cd /tmp/1 #boot
  rm boot.scr.uimg
  rm u-boot.bin

  sed config.txt -i -e "s|^kernel=u-boot.bin|kernel=zImage|"
  echo "initramfs=ramdisk.img 0x01F00000" >> config.txt

  read -r line <cmdline.txt
  echo "initrd=0x01F00000" $line >cmdline.txt
fi

convert_image ramdisk
convert_image recovery

cd /tmp

umount /tmp/1
umount /tmp/2
umount /tmp/3
umount /tmp/4
rmdir 1
rmdir 2
rmdir 3
rmdir 4

