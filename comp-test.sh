#!/bin/bash
#Automated ZFS compressiontest

now=$(date +%s)

cd ./zfs
echo "Make sure ZFS is unloaded and make is cleaned"
sudo ./scripts/zfs.sh -u
sudo ./scripts/zfs-helpers.sh -r
make -s distclean >> /dev/null


echo "Rebuilding ZFS"
sh autogen.sh >> /dev/null
./configure --enable-debug >> /dev/null
make -s -j$(nproc) >> /dev/null

echo "Loading ZFS"
sudo ./scripts/zfs-helpers.sh -i
sudo ./scripts/zfs.sh

cd ..

echo "Creating ramdisk"
sudo mkdir /mnt/ramdisk
sudo mount -t tmpfs -o size=2400m tmpfs /mnt/ramdisk

echo "Creating virtial pool drive"
truncate -s 1200M /mnt/ramdisk/pooldisk.img

echo "Creating zfs testpool/fs1"
sudo ./zfs/cmd/zpool/zpool create testpool -f -o ashift=12  /mnt/ramdisk/pooldisk.img
sudo ./zfs/cmd/zfs/zfs create testpool/fs1

echo "Downloading and extracting enwik9 testset"
sudo wget -nc http://mattmahoney.net/dc/enwik9.zip
sudo unzip -n enwik9.zip

echo "copying enwik9 to ramdisk"
sudo cp enwik9 /mnt/ramdisk/
cd /mnt/ramdisk/
chksum=`sha256sum enwik9`
cd -

echo "starting compression test suite"
for comp in off lz4 zle lzjb gzip zstd
do
echo "" >> ./test_results_$now.txt
echo "running compression test for $comp"
sudo ./zfs/cmd/zfs/zfs set compression=$comp testpool/fs1
sudo echo “results for $comp” >> ./test_results_$now.txt
sudo dd if=/mnt/ramdisk/enwik9 of=/testpool/fs1/enwik9 bs=1024  2>> ./test_results_$now.txt
sudo ./zfs/cmd/zfs/zfs get compressratio testpool/fs1 >> ./test_results_$now.txt

echo "verifying testhash"
cd /testpool/fs1/
chkresult=`echo "$chksum" | sha256sum --check`
sudo rm enwik9
cd -
echo "Hashcheck result: $chkresult" >> ./test_results_$now.txt
done

echo "compression test finished"
echo "Destroying pool and unmounting randisk"
sudo ./zfs/cmd/zpool/zpool destroy testpool
sudo umount -l /mnt/ramdisk

echo "unloading and unlinking zfs"
cd zfs
sudo ./scripts/zfs.sh -u
sudo ./scripts/zfs-helpers.sh -r
make distclean >> /dev/null
cd ..

echo "Done. results writen to test_results_$now.txt "
