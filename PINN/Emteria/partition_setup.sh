#!/bin/sh

set -ex


if [ -z "$part1" ] || [ -z "$part2" ]; then
  printf "Error: missing environment variable part1 or part2\n" 1>&2
  exit 1
fi

p2=`echo ${part2} | sed -e 's/dev/dev\/block/g'`
p3=`echo ${part3} | sed -e 's/dev/dev\/block/g'`
p4=`echo ${part4} | sed -e 's/dev/dev\/block/g'`

mkdir -p /tmp/1 /tmp/2 /tmp/3 /tmp/4

mount "$part1" /tmp/1
mount "$part2" /tmp/2
mount "$part3" /tmp/3
mount "$part4" /tmp/4

#-----------------------------
cd /tmp/1 #boot
mv ramdisk.uimg /tmp/4/ramdisk.uimg
cd /tmp/4
tail -c+65 <ramdisk.uimg >ramdisk.cpio.gz
gunzip ramdisk.cpio.gz
mkdir /tmp/4/tmp
cd tmp
cpio -i -F ../ramdisk.cpio

#device=`grep "^/dev.* /system" fstab.rpi3 | cut -d ' ' -f1 | cut -d 'p' -f1`

sed fstab.rpi3 -i -e "s|^/dev.* /boot   |$p1  /boot |"
sed fstab.rpi3 -i -e "s|^/dev.* /system |$p2  /system |"
sed fstab.rpi3 -i -e "s|^/dev.* /oem    |$p3  /oem |"
sed fstab.rpi3 -i -e "s|^/dev.* /data   |$p4  /data |"

cpio -i -t -F ../ramdisk.cpio | cpio -o -H newc >../ramdisk_new.cpio
cd ..
rm ramdisk.cpio
mv ramdisk_new.cpio ramdisk.cpio
gzip ramdisk.cpio
mkimage -A arm -O Linux -T ramdisk -C gzip -d ramdisk.cpio.gz ramdisk.uimg
mv ramdisk.uimg /tmp/1/ramdisk.uimg
rm -rf /tmp/4/tmp

#-----------------------------
cd /tmp

umount /tmp/1
umount /tmp/2
umount /tmp/3
umount /tmp/4
rmdir 1
rmdir 2
rmdir 3
rmdir 4

