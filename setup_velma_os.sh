#!/bin/bash

export LANG=en_US.UTF-8

# useful functions
function usage {
  echo "usage: $0 extend_directory build_directory build_type [-i install_directory]"
}

function printError {
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo -e "${RED}$1${NC}"
}

install_dir=""

if [ $# -eq 5 ] && [ "$4" == "-i" ]; then
    install_dir=$5
elif [ $# -ne 3 ]; then
    echo "Wrong number of arguments."
    usage
    exit 1
fi

if [ -z "$1" ]; then
    echo "Wrong argument: $1"
    usage
    exit 1
fi

extend_dir="$1"
build_dir="$2"
build_type="$3"

if [ ! -d $build_dir ]; then
  mkdir $build_dir
fi

FRI_DIR=`pwd`

cd $build_dir

if [ ! -e ".rosinstall" ]; then
  wstool init
fi

wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/common_velma.rosinstall        -O /tmp/common_velma.rosinstall

wstool merge /tmp/common_velma.rosinstall

wstool update

if [ -d "$build_dir/src/lwr_hardware/kuka_lwr_fri/include/kuka_lwr_fri" ]; then
    # copy friComm.h
    cp -f "$FRI_DIR/friComm.h" "$build_dir/src/lwr_hardware/kuka_lwr_fri/include/kuka_lwr_fri/"
    if [ $? -eq 0 ]; then
        echo "cp friComm.h OK"
    else
        printError "cp friComm.h FAILED, fri dir: $FRI_DIR"
        exit 1
    fi
fi

if [ -z "$install_dir" ]; then
    catkin config --extend "$extend_dir" --cmake-args -DCMAKE_BUILD_TYPE="$build_type" -DCATKIN_ENABLE_TESTING=OFF
else
    catkin config -i "$install_dir/install" --install --extend "$extend_dir" --cmake-args -DCMAKE_BUILD_TYPE="$build_type" -DCATKIN_ENABLE_TESTING=OFF
fi
catkin build --no-status

