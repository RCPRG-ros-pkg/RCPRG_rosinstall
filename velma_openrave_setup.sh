#!/bin/bash


export LANG=en_US.UTF-8

function usage {
  echo "usage: $0 directory gnulinux|xenomai"
}

if [ $# -ne 2 ]; then 
  usage
  exit 1
fi

if [ -z "$1" ]; then
  usage
  exit 1
fi

if [ "gnulinux" = $2 ]; then
  export OROCOS_TARGET=gnulinux
else
  if [ "xenomai" = $2 ]; then
    export XENOMAI_ROOT_DIR=/opt/xenomai
    export PATH=/opt/xenomai/bin/:$PATH
    export OROCOS_TARGET=xenomai
  else
    usage
    exit 1
  fi
fi

wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/velma_openrave.rosinstall -O /tmp/velma.rosinstall

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
source install_isolated/setup.bash
cd ../underlay
catkin_make -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCATKIN_ENABLE_TESTING=OFF
source devel/setup.bash
