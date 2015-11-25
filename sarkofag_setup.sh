#!/bin/bash

export LANG=en_US.UTF-8
export LANGUAGE=en

wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/sarkofag.rosinstall -O /tmp/sarkofag.rosinstall

if [ ! -d $1 ]; then
  mkdir $1
fi

cd $1
wstool init
wstool merge /tmp/sarkofag.rosinstall
wstool update
cd underlay_isolated
catkin_make_isolated --install -DENABLE_CORBA=ON -DCORBA_IMPLEMENTATION=OMNIORB -DCMAKE_BUILD_TYPE=RelWithDebInfo
source install_isolated/setup.bash
cd ../underlay
catkin_make_isolated -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCATKIN_ENABLE_TESTING=OFF --install
source install_isolated/setup.bash
cd ../robot
catkin_make_isolated -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCATKIN_ENABLE_TESTING=OFF
source devel_isolated/setup.bash
