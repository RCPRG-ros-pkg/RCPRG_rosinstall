#!/bin/bash

export LANG=en_US.UTF-8

function usage {
  echo "usage: $0 directory"
}

if [ $# -ne 1 ]; then 
  usage
  exit 1
fi

if [ -z "$1" ]; then
  usage
  exit 1
fi

wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/barretthand_sim.rosinstall -O /tmp/barretthand_sim.rosinstall
#cp ~/code/RCPRG_rosinstall/barretthand_sim.rosinstall /tmp/barretthand_sim.rosinstall

if [ ! -d "$1" ]; then
  mkdir "$1"
fi

cd "$1"

if [ ! -e ".rosinstall" ]; then
  wstool init
fi

wstool merge /tmp/barretthand_sim.rosinstall
wstool update

wget https://raw.githubusercontent.com/dseredyn/pcl_patch/master/CMakeLists.txt -O underlay/src/pcl/CMakeLists.txt
wget https://raw.githubusercontent.com/dseredyn/pcl_patch/master/package.xml -O underlay/src/pcl/package.xml

cd underlay

catkin config --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_SHARED_LIBS=ON   -DUSE_DOUBLE_PRECISION=ON
catkin build

cd ../sim
catkin config --extend ../underlay/devel/ --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo
catkin build

