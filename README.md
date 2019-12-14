
# zfs-compression-test
Crude Standardised ZFS compression test, with repeatable results in mind

## Important notes
- Make sure you do not have zfs installed already via other means
- This assumes a clean install with sudo, unzip, wget and git installed
- The enwik9 dataset gets downloaded just once, don;t worry about the time it takes
- This script makes sure the build/test environment is as prestine as possible before and after running
- This script uses a ramdisk as source and (pool) destination for writes tests to asure clean and unbottlenecked results

## How setup

1. Install all dependancies as described here: https://github.com/zfsonlinux/zfs/wiki/Building-ZFS#installing-dependencies
2. Run: git clone https://github.com/Ornias1993/zfs-compression-test
3. Run: cd zfs-compression-test
3. Clone the branch/repo containing ZoL (ex. git clone https://github.com/zfsonlinux/zfs 

By now you'll have all dependencies and you'll have a clean git clone in zfs-compression-test/zfs

## How to use
1. Make sure you cd into the zfs-compression-test directory
2. run: sudo ./comp-test.sh with one of the **options**

## options

**Compression Tests**
- **-b** A basic test of only the following algorithms: off lz4 zle lzjb gzip zstd
- **-f** A full test of all compression algorithms available for ZFS
- **-c** A Custom test with only the argument algorithm
- **-t** Select a different compression test file. Options: `enwik9` and `mpeg4`
- **-p** Enter a different prefix for the test results

**Other**
- **-i** Builds and installs the ZFS testing environment (included for compression tests)
- **-r** Completely removes the ZFS testing environment (included for compression tests)
- **-h** Displays a help page, which includes a reference to the different commands

When finished you'll have a .txt file in the zfs-compression-test directory, containing the test results


### To Do
- Add custom ram setting
- Automatic run of tests and zloop
- Combinations of Tests, Zloop and Compression
- Input sanitsaion
