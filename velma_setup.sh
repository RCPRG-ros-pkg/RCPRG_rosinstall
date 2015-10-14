#!/bin/bash

export XENOMAI_ROOT_DIR=/opt/xenomai
export PATH=/opt/xenomai/bin/:$PATH
export LANG=en_US.UTF-8
export OROCOS_TARGET=xenomai

wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/velma.rosinstall -O /tmp/velma.rosinstall

if [ ! -d $1 ]; then
  mkdir $1
fi

FRI_DIR=`pwd`

cd $1
wstool init
wstool merge /tmp/velma.rosinstall
wstool update
cp $FRI_DIR/friComm.h underlay/src/lwr_hardware/kuka_lwr_fri/include/kuka_lwr_fri/
cd underlay_isolated
catkin_make_isolated --install -DENABLE_CORBA=ON -DCORBA_IMPLEMENTATION=OMNIORB -DCMAKE_BUILD_TYPE=RelWithDebInfo
cd ../underlay
catkin config --extend $1/underlay_isolated/install_isolated/ --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCATKIN_ENABLE_TESTING=OFF
catkin build
source devel/setup.bash
