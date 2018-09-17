#!/bin/bash


export LANG=en_US.UTF-8
export OROCOS_TARGET=gnulinux

# useful functions
function usage {
  echo "usage: $0 directory"
}

function printError {
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo -e "${RED}$1${NC}"
}

if [ $# -ne 1 ]; then 
  usage
  exit 1
fi

if [ -z "$1" ]; then
  usage
  exit 1
fi

distro="$ROS_DISTRO"

if [ "$distro" != "kinetic" ]; then
    printError "ERROR: ROS kinetic setup.bash have to be sourced!"
    exit 1
fi

wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/common_orocos.rosinstall           -O /tmp/common_orocos.rosinstall
wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/barrett_hand_hw.rosinstall         -O /tmp/barrett_hand_hw.rosinstall

build_dir=$1

if [ ! -d $build_dir ]; then
  mkdir $build_dir
fi

FRI_DIR=`pwd`

cd $build_dir

if [ ! -e ".rosinstall" ]; then
  wstool init
fi

wstool merge /tmp/common_orocos.rosinstall
wstool merge /tmp/barrett_hand_hw.rosinstall

wstool update

cd underlay_isolated
catkin_make_isolated --install -DENABLE_CORBA=ON -DCORBA_IMPLEMENTATION=OMNIORB -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_CORE_ONLY=ON   -DBUILD_SHARED_LIBS=ON   -DUSE_DOUBLE_PRECISION=ON

if [ $? -eq 0 ]; then
    echo "underlay_isolated build OK"
else
    printError "underlay_isolated build FAILED"
    exit 1
fi

cd ../underlay
catkin config --extend ../underlay_isolated/install_isolated/ --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCATKIN_ENABLE_TESTING=OFF
catkin build

