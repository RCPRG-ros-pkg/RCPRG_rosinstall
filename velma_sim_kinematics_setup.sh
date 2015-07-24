#!/bin/bash


export LANG=en_US.UTF-8
export OROCOS_TARGET=gnulinux

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

wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/velma_sim_kinematics.rosinstall -O /tmp/velma_sim_kinematics.rosinstall

if [ ! -d $1 ]; then
  mkdir $1
fi

FRI_DIR=`pwd`

cd $1
wstool init
wstool merge /tmp/velma_sim_kinematics.rosinstall
wstool update
cd underlay_isolated
catkin_make_isolated --install -DENABLE_CORBA=ON -DCORBA_IMPLEMENTATION=OMNIORB -DCMAKE_BUILD_TYPE=RelWithDebInfo
source install_isolated/setup.bash
cd ../underlay
catkin_make -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCATKIN_ENABLE_TESTING=OFF
source devel/setup.bash
