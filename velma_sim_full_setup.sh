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

wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/velma_sim_full.rosinstall -O /tmp/velma_sim_full.rosinstall
#cp ~/code/RCPRG_rosinstall/velma_sim_full.rosinstall /tmp/velma_sim_full.rosinstall

#wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/velma.rosinstall -O /tmp/velma.rosinstall
#wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/openrave.rosinstall -O /tmp/openrave.rosinstall

if [ ! -d $1 ]; then
  mkdir $1
fi

FRI_DIR=`pwd`

cd $1

if [ ! -e ".rosinstall" ]; then
  wstool init
fi

wstool merge /tmp/velma_sim_full.rosinstall
#wstool merge /tmp/velma.rosinstall
#wstool merge /tmp/openrave.rosinstall

wstool update

curl https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_dart-core.xml > underlay_isolated/src/dart/package.xml
curl https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_sdformat.xml  > underlay_isolated/src/sdformat/package.xml
curl https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_gazebo.xml    > underlay_isolated/src/gazebo/package.xml
curl https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_ign-math.xml  > underlay_isolated/src/ign-math/package.xml

#cp $FRI_DIR/friComm.h underlay/src/lwr_hardware/kuka_lwr_fri/include/kuka_lwr_fri/
cd underlay_isolated
catkin_make_isolated --install -DENABLE_CORBA=ON -DCORBA_IMPLEMENTATION=OMNIORB -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_CORE_ONLY=ON   -DBUILD_SHARED_LIBS=ON   -DUSE_DOUBLE_PRECISION=ON
source install_isolated/setup.bash
cd ../underlay
catkin_make -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCATKIN_ENABLE_TESTING=OFF
source devel/setup.bash
cd ../sim
catkin_make -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCATKIN_ENABLE_TESTING=OFF
source devel/setup.bash
