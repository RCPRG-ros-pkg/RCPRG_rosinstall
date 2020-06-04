#!/usr/bin/env bash

function usage {
	echo "usage: $0 build_dir"
}

function printError {
	RED='\033[0;31m'
	NC='\033[0m'
	echo -e "${RED}$1${NC}"
}

if [ "$#" -ne 1 ]; then
    printError "Wrong number of parameters"
    usage
    exit 1
fi

### Argument parsing:
build_dir="$1"

if [ ! -d "$build_dir" ]; then
    printError "Directory $build_dir does not exist"
    exit 1
fi

script_dir=`pwd`

### Fakeroot
### install fakechroot if not present
if [ -x "$(fakechroot -v)" ]; then
	echo "WARNING: fakechroot not installed, please install it: sudo apt install fakechroot"
	exit 1
fi

### Prepare the jail
mkdir -p $build_dir/bin
mkdir -p $build_dir/dev
#mkdir -p $build_dir/etc
#cp -r /etc/* $build_dir/etc
mkdir -p $build_dir/lib
mkdir -p $build_dir/lib64
mkdir -p $build_dir/opt
mkdir -p $build_dir/proc
mkdir -p $build_dir/sbin
mkdir -p $build_dir/tmp
mkdir -p $build_dir/usr
mkdir -p $build_dir/var

## link in /opt/ros (if not linked already)
#if [[ ! -d $build_dir/opt/ros ]]; then
#	ln -s /opt/ros $build_dir/opt/ros
#fi

### Enter jail
cd $build_dir

### Execute build in jail
# perform fakechroot and execute bash, in jail
echo "Executing:"
echo "fakechroot -e jail -c $script_dir/fakechroot fakeroot /usr/sbin/chroot . bash"
fakechroot -s -e jail -c $script_dir/fakechroot fakeroot /usr/sbin/chroot --userspec=robot:robot . bash
exit 0
