#!/bin/bash

export LANG=en_US.UTF-8
export OROCOS_TARGET=xenomai

wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/velma.rosinstall -O /tmp/velma.rosinstall

if [ ! -d $1 ]; then
  mkdir $1
fi
cd $1
wstool init
wstool merge /tmp/velma.rosinstall
wstool update
cp ../friComm.h underlay/src/lwr_hardware/kuka_lwr_fri/include/kuka_lwr_fri/
cd underlay_isolated
catkin_make_isolated --install -DENABLE_CORBA=ON -DCORBA_IMPLEMENTATION=OMNIORB -DCMAKE_BUILD_TYPE=RelWithDebInfo
source install_isolated/setup.bash
cd ../underlay
catkin_make -DCMAKE_BUILD_TYPE=RelWithDebInfo
source devel/setup.bash
