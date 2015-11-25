#!/bin/bash

export LANG=en_US.UTF-8
export OROCOS_TARGET=gnulinux

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
catkin config --extend $1/underlay_isolated/install_isolated/ --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCATKIN_ENABLE_TESTING=OFF
catkin build
source devel/setup.bash
