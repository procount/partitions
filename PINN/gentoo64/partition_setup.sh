#!/bin/sh

set -ex

if [ -z "$part1" ] || [ -z "$part2" ]; then
  printf "Error: missing environment variable part1 or part2\n" 1>&2
  exit 1
fi

mkdir -p /tmp/1 /tmp/2

mount "$part1" /tmp/1
mount "$part2" /tmp/2

#update root partition ref in cmdline.txt, keeping the timestamps the same
mv /tmp/1/cmdline.txt /tmp/1/cmdline.bak	#Keeps timestamp
cp /tmp/1/cmdline.bak /tmp/1/cmdline.txt	#timestamp updated
sed /tmp/1/cmdline.txt -i -e "s|root=[^ ]*|root=${part2}|"
touch -r /tmp/1/cmdline.bak /tmp/1/cmdline.txt	#restore timestamp
rm /tmp/1/cmdline.bak

#Update partition refs in fstab, keeping the timestamps the same
mv /tmp/2/etc/fstab /tmp/2/etc/fstab.bak	#Keeps timestamp
cp /tmp/2/etc/fstab.bak  /tmp/2/etc/fstab	#timestamp updated
sed /tmp/2/etc/fstab -i -e "s|\t| |g"
sed /tmp/2/etc/fstab -i -e "s|^[^#].* / |${part2}  / |"
sed /tmp/2/etc/fstab -i -e "s|^[^#].* /boot |${part1}  /boot |"

#Hide /Settings from gentoo filemanager by mounting it 'noauto'
mkdir -p /tmp/2/mnt/Settings
len=${#part2}
c2=`echo $part2 | cut -c$len`
let len-=1
c1=`echo $part2 | cut -c$len`
let len-=1

if [ $c1 == "1" -o $c1 == "2" ]; then
	c1="0"
fi
if [ ${part2:0:4} != "PART" -a $c1 == "0" ]; then
	c1=""
fi
c2="5"
part3=${part2:0:$len}$c1$c2
echo "${part3} /mnt/Settings ext4 defaults,noatime,noauto 0 0" >>/tmp/2/etc/fstab

touch -r /tmp/2/etc/fstab.bak /tmp/2/etc/fstab	#restore timestamp
rm /tmp/2/etc/fstab.bak

#Prevent root partition expansion - already done by PINN
mv /tmp/1/autoexpand_root_partition /tmp/1/autoexpand_root_none #Keeps timestamp

#Modify last shutdowntime (if necessary) to prevent fsck on first boot
datelt()
{
	# remove everything but digits from input parameters
	local D1=`echo $1 | tr -cd "[:digit:]"`
	local D2=`echo $2 | tr -cd "[:digit:]"`
	local D1DATE="${D1:0:8}"
	local D2DATE="${D2:0:8}"
	local D1TIME="${D1:8:4}" # ignore trailing 4 digits (timezone?)
	local D2TIME="${D2:8:4}"
	[ $D1DATE -lt $D2DATE ] || [ $D1DATE -eq $D2DATE -a $D1TIME -lt $D2TIME ]
	#0 means D1<D2	
}


file=/tmp/2/lib64/rc/cache/shutdowntime

timeNow=`date -Iminutes`
timeLastWrite=`date -Iminutes -r $file`
#if shutdowntime is less than time now, then update the file's timestamp to now
datelt $timeLastWrite $timeNow && touch $file

umount /tmp/1
umount /tmp/2
