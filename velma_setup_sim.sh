#!/bin/bash

export XENOMAI_ROOT_DIR=/opt/xenomai
export PATH=/opt/xenomai/bin/:$PATH
export LANG=en_US.UTF-8
export OROCOS_TARGET=gnulinux

wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/velma_sim.rosinstall -O /tmp/velma_sim.rosinstall

if [ ! -d $1 ]; then
  mkdir $1
fi

FRI_DIR=`pwd`

cd $1
wstool init
wstool merge /tmp/velma_sim.rosinstall
wstool update
cd underlay_isolated
catkin_make_isolated --install -DENABLE_CORBA=ON -DCORBA_IMPLEMENTATION=OMNIORB -DCMAKE_BUILD_TYPE=RelWithDebInfo
source install_isolated/setup.bash
cd ../underlay
catkin_make -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCATKIN_ENABLE_TESTING=OFF
source devel/setup.bash
