#!/bin/bash

# the list of packages that should be installed
installed=(ros-indigo-desktop)

# the list of packages that should be uninstalled
uninstalled=(ros-indigo-desktop-full libdart libsdformat gazebo)

export LANG=en_US.UTF-8
export OROCOS_TARGET=gnulinux

# useful functions
function usage {
  echo "usage: $0 directory"
}

function printError {
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo -e "${RED}$1${NC}"
}

if [ $# -ne 1 ]; then 
  usage
  exit 1
fi

if [ -z "$1" ]; then
  usage
  exit 1
fi

if [ "$ROS_DISTRO" != "indigo" ]; then
    printError "ERROR: ROS Indigo setup.bash have to be sourced!"
    exit 1
fi

error=false

# check the list of packages that should be installed
for item in ${installed[*]}
do
    aaa=`dpkg --get-selections | grep $item`
    if [ -z "$aaa" ]; then
        printError "ERROR: package $item is not installed. Please INSTALL it."
        error=true
    else
        arr=($aaa)
        name=${arr[0]}
        status=${arr[1]}
        if [ "$status" != "install" ]; then
            printError "ERROR: package $name is not installed. Please INSTALL it."
            error=true
        else
            echo "OK: package $name is installed"
        fi
    fi
done

# check the list of packages that should be uninstalled
for item in ${uninstalled[*]}
do
    aaa=`dpkg --get-selections | grep $item`
    if [ -z "$aaa" ]; then
        echo "OK: the package $item is not installed."
    else
        arr=($aaa)
        name=${arr[0]}
        status=${arr[1]}
        if [ "$status" != "install" ]; then
            echo "OK: the package $name is not installed."
        else
            printError "ERROR: package $name is installed. Please UNINSTALL it."
            error=true
        fi
    fi
done

if [ "$error" = true ]; then
    echo "Please install/uninstall the listed packages"
    exit 1
fi

wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/velma_sim_full.rosinstall -O /tmp/velma_sim_full.rosinstall

if [ ! -d $1 ]; then
  mkdir $1
fi

FRI_DIR=`pwd`

cd $1

if [ ! -e ".rosinstall" ]; then
  wstool init
fi

wstool merge /tmp/velma_sim_full.rosinstall

wstool update

# download package.xml for some packages
wget https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_dart-core.xml -O underlay_isolated/src/gazebo/dart/package.xml
wget https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_sdformat.xml  -O underlay_isolated/src/gazebo/sdformat/package.xml
wget https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_gazebo.xml    -O underlay_isolated/src/gazebo/gazebo/package.xml
wget https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_ign-math.xml  -O underlay_isolated/src/gazebo/ign-math/package.xml

# apply the patch for DART collision shapes transformation
wget https://bitbucket.org/jlee02/gazebo_dart/raw/f7da5e89fa3e9d8ec5fee960a4b8b33ec195c8a3/gazebo/physics/dart/DARTCollision.cc -O underlay_isolated/src/gazebo/gazebo/gazebo/physics/dart/DARTCollision.cc
wget https://bitbucket.org/jlee02/gazebo_dart/raw/f7da5e89fa3e9d8ec5fee960a4b8b33ec195c8a3/gazebo/physics/dart/DARTTypes.hh -O underlay_isolated/src/gazebo/gazebo/gazebo/physics/dart/DARTTypes.hh

cd underlay_isolated
catkin_make_isolated --install -DENABLE_CORBA=ON -DCORBA_IMPLEMENTATION=OMNIORB -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_CORE_ONLY=ON   -DBUILD_SHARED_LIBS=ON   -DUSE_DOUBLE_PRECISION=ON
source install_isolated/setup.bash
cd ../underlay
catkin_make -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCATKIN_ENABLE_TESTING=OFF
source devel/setup.bash
cd ../sim
catkin_make -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCATKIN_ENABLE_TESTING=OFF
source devel/setup.bash

