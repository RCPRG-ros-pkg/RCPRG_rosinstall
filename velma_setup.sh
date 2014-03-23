#!/bin/bash

export OROCOS_TARGET=xenomai

mkdir ws_velma
cd ws_velma
wstool init
wstool merge ../velma_sim.rosinstall
wstool update
cp ../friComm.h underlay/src/lwr_hardware/kuka_lwr_fri/include/kuka_lwr_fri/
cd underlay_isolated
catkin_make_isolated --install -DENABLE_CORBA=ON -DCORBA_IMPLEMENTATION=OMNIORB
source install_isolated/setup.bash
cd ../underlay
catkin_make
source devel/setup.bash
