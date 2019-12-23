#!/bin/bash
#Automated ZFS compressiontest

BRANCH="master"
git fetch
git update-index -q --refresh
CHANGED=$(git diff --name-only origin/$BRANCH)
if [ ! -z "$CHANGED" ];
then
    echo "script requires update"
    git reset --hard
    git checkout $BRANCH
    git pull
    echo "script updated"
    exit 1
else
    echo "script up-to-date"
fi


now=$(date +%s)

MODE="NONE"
GZIP="gzip gzip-1 gzip-2 gzip-3 gzip-4 gzip-5 gzip-6 gzip-7 gzip-8 gzip-9"
ZSTD="zstd zstd-1 zstd-2 zstd-3 zstd-4 zstd-5 zstd-6 zstd-7 zstd-8 zstd-9 zstd-10 zstd-11 zstd-12 zstd-13 zstd-14 zstd-15 zstd-16 zstd-17 zstd-18 zstd-19"
ZSTDFAST="zstd-fast zstd-fast-1 zstd-fast-2 zstd-fast-3 zstd-fast-4 zstd-fast-5 zstd-fast-6 zstd-fast-7 zstd-fast-8 zstd-fast-9 zstd-fast-10 zstd-fast-20 zstd-fast-30 zstd-fast-40 zstd-fast-50 zstd-fast-60 zstd-fast-70 zstd-fast-80 zstd-fast-90 zstd-fast-100 zstd-fast-500 zstd-fast-1000"
TYPE="WIKIPEDIA"
TESTRESULTS="test_results_$now.txt"
if [ $# -eq 0 ]
then
        echo "Missing options!"
        echo "(run $0 -h for help)"
        echo ""
        exit 0
fi

while getopts "p:t:ribfhc:" OPTION; do
        case $OPTION in
		p)	
			TESTRESULTS="$OPTARG-$TESTRESULTS"
			echo "Results file of the test is called: ./$TESTRESULTS"
			
			;;
		t)	
			TYPE="$OPTARG"
			case $TYPE in
				[wW])	
					echo "Selected highly compressible Wikipedia file"
					TYPE="WIKIPEDIA"
					;;
				[mM])
					echo "Selected nearly uncompressible MPEG4 file"
					TYPE="MPEG4"
					;;
				*)	
					echo "Unknown Selection of Testtype. Using default"
				       	TYPE="WIKIPEDIA"
					;;	
			esac
			;;
                r)
                        MODE="RESET"
                        echo "Selected RESET of ZSTD test-installation"
                        ;;
                i)
                        MODE="INSTALL"
                        echo "Selected INSTALL of ZSTD test-installation"
                        ;;
                b)
                        MODE="BASIC"
                        ALGO="off lz4 zle lzjb gzip zstd"
                        echo "Selected BASIC compression test"
                        ;;
                f)
                        MODE="FULL"
                        ALGO="off lz4 zle lzjb $GZIP $ZSTD $ZSTDFAST"
                        echo "Selected FULL compression test"
                        echo "This might take a while..."
                        ;;
                c)
                        MODE="CUSTOM"
                        ALGO="$OPTARG"
                        echo "Selected custom compression test using the following algorithms:"
                        echo "$ALGO"
                        ;;
                h)
                        echo "Usage:"
                        echo "$0 -h "
                        echo "$0 -b "
                        echo "$0 -basic "
                        echo "$0 -f "
                        echo "$0 -full "
                        echo ""
                        echo "$0 -i  "
                        echo "$0 -r "
                        echo ""
                        echo "   -b    to execute a basic compression test containing: off lz4 zle lzjb gzip zstd"
                        echo "   -f    to execute a full compression test containing all currently available ZFS compression algorithms"
			echo "   -c    to execute the entered list of following compression types: "
			echo "         off lz4 zle lzjb $GZIP"
			echo "         $ZSTD"
		       	echo "         $ZSTDFAST"
                        echo ""
                        echo "   -i to install a ZFS test environment"
                        echo "   -r to reset a ZFS test environment"
			echo "   -p to enter a prefix to the test_result files"
			echo "   -t to select the type of test:"
			echo "      w for highly compressible wikipedia file"
			echo "      m for nearly uncompressible mpeg4 file"
                        echo "   -h     help (this output)"
                        echo "ALL these values are mutually exclusive"
                        exit 0
                        ;;

        esac
done

echo "checking if you git cloned zfs"
[ ! -e ./zfs/.git ] && { echo "You need to clone zfs first! # git clone https://github.com/zfsonlinux/zfs"; exit 1; }

if [ $MODE = "RESET" ]
then
        echo "destroy testpool and unmount ramdisk of previous broken/canceled tests"
        test -f ./zfs/cmd/zpool/zpool && sudo ./zfs/cmd/zpool/zpool destroy testpool 2>&1 >/dev/null
        sudo umount -l /mnt/ramdisk >/dev/null 2>&1

        cd ./zfs
        echo "make sure zfs is unloaded and make is cleaned"
        sudo ./scripts/zfs.sh -u
        sudo ./scripts/zfs-helpers.sh -r
        make -s distclean >> /dev/null
fi

if [ $MODE = "INSTALL" ]
then
        cd ./zfs
        echo "rebuilding zfs"
        sh autogen.sh >> /dev/null
        ./configure --enable-debug >> /dev/null
        make -s -j$(nproc) >> /dev/null

        echo "loading zfs"
        sudo ./scripts/zfs-helpers.sh -i
        sudo ./scripts/zfs.sh
fi

if [  $MODE = "FULL" -o $MODE = "BASIC" -o $MODE = "CUSTOM" ]
then
        echo "destroy testpool and unmount ramdisk of previous broken/canceled tests"
        test -f ./zfs/cmd/zpool/zpool && sudo ./zfs/cmd/zpool/zpool destroy testpool 2>&1 >/dev/null
        sudo umount -l /mnt/ramdisk >/dev/null 2>&1

        cd ./zfs
        echo "make sure zfs is unloaded and make is cleaned"
        sudo ./scripts/zfs.sh -u
        sudo ./scripts/zfs-helpers.sh -r
        make -s distclean >> /dev/null


        echo "rebuilding zfs"
        sh autogen.sh >> /dev/null
        ./configure --enable-debug >> /dev/null
        make -s -j$(nproc) >> /dev/null

        echo "loading zfs"
        sudo ./scripts/zfs-helpers.sh -i
        sudo ./scripts/zfs.sh

        cd ..
        echo "creating ramdisk"
        sudo mkdir /mnt/ramdisk
        sudo mount -t tmpfs -o size=2400m tmpfs /mnt/ramdisk

        echo "creating virtual pool drive"
        truncate -s 1200m /mnt/ramdisk/pooldisk.img

        echo "creating zfs testpool/fs1"
        sudo ./zfs/cmd/zpool/zpool create testpool -f -o ashift=12  /mnt/ramdisk/pooldisk.img
        sudo ./zfs/cmd/zfs/zfs create testpool/fs1
		sudo ./zfs/cmd/zfs/zfs set recordsize=1M  testpool/fs1

	# Downloading and may be uncompressing file 
	FILENAME=""
	case "$TYPE" in 

		WIKIPEDIA)	
        		echo "downloading and extracting enwik9 testset"
        		sudo wget -nc http://mattmahoney.net/dc/enwik9.zip
        		sudo unzip -n enwik9.zip
			FILENAME="enwik9"
			;;
		MPEG4)
			echo "downloading a MPEG4 testfile"
			sudo wget -nc http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_native_60fps_stereo_abl.mp4
			FILENAME="bbb_sunflower_native_60fps_stereo_abl.mp4"
			;;

		*)	
			echo "ERROR: $TYPE is not unknown"
			exit 1
			;;
	esac

        echo "copying $FILENAME to ramdisk, truncating it after 1000M"
	sudo dd if=$FILENAME of=/mnt/ramdisk/$FILENAME bs=1M count=1000 status=none
        cd /mnt/ramdisk/
        chksum=`sha256sum $FILENAME`
        cd -
        echo "" >> "./$TESTRESULTS"
        echo "Test with $FILENAME file" >> "./$TESTRESULTS"
	grep "^model name" /proc/cpuinfo |sort -u >> "./$TESTRESULTS"
	grep "^flags" /proc/cpuinfo |sort -u >>  "./$TESTRESULTS"
	echo "" >> "./$TESTRESULTS"

        echo "starting compression test suite"
        for comp in $ALGO
        do
                echo "running compression test for $comp"
                ./zfs/cmd/zfs/zfs set compression=$comp testpool/fs1
		if [ $? -ne 0 ];
		then
			echo "Could not set compression to $comp! Skipping test."
		else
                	echo “Compression results for $comp” >> "./$TESTRESULTS"
                	dd if=/mnt/ramdisk/$FILENAME of=/testpool/fs1/$FILENAME bs=4M 2>&1 |grep -v records >> "./$TESTRESULTS"
                	./zfs/cmd/zfs/zfs get compressratio testpool/fs1 >> "./$TESTRESULTS"
                	echo "" >> "./$TESTRESULTS"
                	echo “Decompression results for $comp” >> "./$TESTRESULTS"
                	dd if=/testpool/fs1/$FILENAME of=/dev/null bs=4M 2>&1 |grep -v records >> "./$TESTRESULTS"
                	echo ""  >> "./$TESTRESULTS"
                	echo "verifying testhash"
                	cd /testpool/fs1/
                	chkresult=`echo "$chksum" | sha256sum --check`
                	sudo rm $FILENAME
                	cd -
                	echo "hashcheck result: $chkresult" >> "./$TESTRESULTS"
                	echo "" >> "./$TESTRESULTS"
                	echo "----" >> "./$TESTRESULTS"
                	echo "" >> "./$TESTRESULTS"
		fi
        done

        echo "compression test finished"
        echo "destroying pool and unmounting ramdisk"
        sudo ./zfs/cmd/zpool/zpool destroy testpool
        sudo umount -l /mnt/ramdisk
        echo "unloading and unlinking zfs"
        cd zfs
        sudo ./scripts/zfs.sh -u
        sudo ./scripts/zfs-helpers.sh -r
        make distclean >> /dev/null
        cd ..

        echo "Done. results written to ./$TESTRESULTS"
fi
