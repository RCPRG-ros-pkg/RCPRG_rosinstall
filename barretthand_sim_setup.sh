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

wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/barretthand_sim.rosinstall -O /tmp/barretthand_sim.rosinstall

if [ ! -d $1 ]; then
  mkdir $1
fi

cd $1
wstool init
wstool merge /tmp/barretthand_sim.rosinstall
wstool update
cd underlay_isolated
catkin_make_isolated --install -DENABLE_CORBA=ON -DCORBA_IMPLEMENTATION=OMNIORB -DCMAKE_BUILD_TYPE=RelWithDebInfo
cd ../underlay
catkin_make -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCATKIN_ENABLE_TESTING=OFF
source devel/setup.bash
