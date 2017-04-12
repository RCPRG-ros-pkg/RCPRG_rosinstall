#!/bin/bash


export LANG=en_US.UTF-8

# useful functions
function usage {
  echo "usage: $0 directory [-xenomai]"
}

function printError {
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo -e "${RED}$1${NC}"
}

if [ $# -ne 1 ] && [ $# -ne 2 ]; then
  usage
  exit 1
fi

if [ -z "$1" ]; then
  usage
  exit 1
fi

if [ $# -eq 2 ] && [ "$2" != "-xenomai" ]; then
  usage
  exit 1
fi

if [ $# -eq 2 ] && [ "$2" == "-xenomai" ]; then
  use_xenomai=true
else
  use_xenomai=false
fi

distro="$ROS_DISTRO"

if [ "$distro" != "kinetic" ]; then
    printError "ERROR: ROS kinetic setup.bash have to be sourced!"
    exit 1
fi

# the list of packages that should be installed
installed=(
"libprotobuf-dev"
"libprotoc-dev"
"protobuf-compiler"
"libtinyxml2-dev"
"libtar-dev"
"libtbb-dev"
"libfreeimage-dev"
"libignition-transport0-dev"
"omniorb"
"omniidl"
"libomniorb4-dev"
"libxerces-c-dev"
"doxygen"
"python-catkin-tools"
"libfcl-dev"
"libqtwebkit-dev"
"libgts-dev"
"ros-$distro-desktop"
"ros-$distro-polled-camera"
"ros-$distro-camera-info-manager"
"ros-$distro-control-toolbox"
"ros-$distro-controller-manager-msgs"
"ros-$distro-controller-manager"
"ros-$distro-urdfdom-py"
"ros-$distro-transmission-interface"
)

# the list of packages that should be uninstalled
uninstalled=(
"ros-$distro-desktop-full"
"libdart"
"libsdformat"
"libignition-math2"
"gazebo"
)

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
    echo "To install libccd please see http://askubuntu.com/questions/664101/dependency-in-ppa"
    exit 1
fi

# test
cp common_orocos.rosinstall       /tmp/common_orocos.rosinstall
cp common_velma.rosinstall        /tmp/common_velma.rosinstall
cp gazebo7_2_dart.rosinstall      /tmp/gazebo7_2_dart.rosinstall
cp velma_sim.rosinstall           /tmp/velma_sim.rosinstall
cp velma_applications.rosinstall  /tmp/velma_applications.rosinstall
if [ "$use_xenomai" = true ]; then
    cp velma_hw.rosinstall        /tmp/velma_hw.rosinstall
fi

#wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/common_orocos.rosinstall       -O /tmp/common_orocos.rosinstall
#wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/common_velma.rosinstall        -O /tmp/common_velma.rosinstall
#wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/gazebo7_2_dart.rosinstall      -O /tmp/gazebo7_2_dart.rosinstall
#wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/velma_sim.rosinstall           -O /tmp/velma_sim.rosinstall
#wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/velma_applications.rosinstall  -O /tmp/velma_applications.rosinstall

build_dir=$1

if [ ! -d $build_dir ]; then
  mkdir $build_dir
fi

FRI_DIR=`pwd`

cd $build_dir

WORKSPACE_ROOT_DIR=`pwd`

#if [ ! -d sources ]; then
mkdir -p sources
#fi

cd sources

if [ ! -e ".rosinstall" ]; then
  wstool init
fi

wstool merge /tmp/common_orocos.rosinstall
wstool merge /tmp/common_velma.rosinstall
wstool merge /tmp/gazebo7_2_dart.rosinstall
wstool merge /tmp/velma_sim.rosinstall
wstool merge /tmp/velma_applications.rosinstall
if [ "$use_xenomai" = true ]; then
    wstool merge /tmp/velma_hw.rosinstall
fi

#TODO: uncomment
#wstool update

# download package.xml for some packages
wget https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_dart-core.xml -O sim/underlay_isolated/gazebo/dart/package.xml
wget https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_sdformat.xml  -O sim/underlay_isolated/gazebo/sdformat/package.xml
wget https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_gazebo.xml    -O sim/underlay_isolated/gazebo/gazebo/package.xml
wget https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_ign-math.xml  -O sim/underlay_isolated/gazebo/ign-math/package.xml

# copy friComm.h
cp -f $FRI_DIR/friComm.h common/underlay/lwr_hardware/kuka_lwr_fri/include/kuka_lwr_fri/
if [ $? -eq 0 ]; then
    echo "cp friComm.h OK"
else
    printError "cp friComm.h FAILED, fri dir: $FRI_DIR"
    exit 1
fi

#
# create workspace directory tree
#
cd $WORKSPACE_ROOT_DIR

mkdir -p sim/underlay_isolated/src
mkdir -p sim/underlay/src
mkdir -p sim/top/src

mkdir -p hw/underlay_isolated/src
mkdir -p hw/underlay/src
mkdir -p hw/top/src

# common
if [ -d sources/common/underlay_isolated ]; then
    common_repos_underlay_isolated=($(ls sources/common/underlay_isolated))
else
    common_repos_underlay_isolated=()
fi

if [ -d sources/common/underlay ]; then
    common_repos_underlay=($(ls sources/common/underlay))
else
    common_repos_underlay=()
fi

if [ -d sources/common/top ]; then
    common_repos_top=($(ls sources/common/top))
else
    common_repos_top=()
fi

# hw
if [ -d sources/hw/underlay_isolated ]; then
    hw_repos_underlay_isolated=($(ls sources/hw/underlay_isolated))
else
    hw_repos_underlay_isolated=()
fi

if [ -d sources/hw/underlay ]; then
    hw_repos_underlay=($(ls sources/hw/underlay))
else
    hw_repos_underlay=()
fi

if [ -d sources/hw/top ]; then
    hw_repos_top=($(ls sources/hw/top))
else
    hw_repos_top=()
fi

# sim
if [ -d sources/sim/underlay_isolated ]; then
    sim_repos_underlay_isolated=($(ls sources/sim/underlay_isolated))
else
    sim_repos_underlay_isolated=()
fi

if [ -d sources/sim/underlay ]; then
    sim_repos_underlay=($(ls sources/sim/underlay))
else
    sim_repos_underlay=()
fi

if [ -d sources/sim/top ]; then
    sim_repos_top=($(ls sources/sim/top))
else
    sim_repos_top=()
fi

#
# create symbolic links
#
function tryCreateLink {
    if [ ! -h $2 ]; then
        ln --symbolic --relative --no-dereference $1 $2
    fi
}

# common
for d in "${common_repos_underlay_isolated[@]}"
do
    tryCreateLink $WORKSPACE_ROOT_DIR/sources/common/underlay_isolated/$d  $WORKSPACE_ROOT_DIR/hw/underlay_isolated/src/$d
    tryCreateLink $WORKSPACE_ROOT_DIR/sources/common/underlay_isolated/$d  $WORKSPACE_ROOT_DIR/sim/underlay_isolated/src/$d
done

for d in "${common_repos_underlay[@]}"
do
    tryCreateLink $WORKSPACE_ROOT_DIR/sources/common/underlay/$d  $WORKSPACE_ROOT_DIR/hw/underlay/src/$d
    tryCreateLink $WORKSPACE_ROOT_DIR/sources/common/underlay/$d  $WORKSPACE_ROOT_DIR/sim/underlay/src/$d
done

for d in "${common_repos_top[@]}"
do
    tryCreateLink $WORKSPACE_ROOT_DIR/sources/common/top/$d  $WORKSPACE_ROOT_DIR/hw/top/src/$d
    tryCreateLink $WORKSPACE_ROOT_DIR/sources/common/top/$d  $WORKSPACE_ROOT_DIR/sim/top/src/$d
done

# sim
for d in "${sim_repos_underlay_isolated[@]}"
do
    tryCreateLink $WORKSPACE_ROOT_DIR/sources/sim/underlay_isolated/$d  $WORKSPACE_ROOT_DIR/sim/underlay_isolated/src/$d
done

for d in "${sim_repos_underlay[@]}"
do
    tryCreateLink $WORKSPACE_ROOT_DIR/sources/sim/underlay/$d  $WORKSPACE_ROOT_DIR/sim/underlay/src/$d
done

for d in "${sim_repos_top[@]}"
do
    tryCreateLink $WORKSPACE_ROOT_DIR/sources/sim/top/$d  $WORKSPACE_ROOT_DIR/sim/top/src/$d
done

# hw
for d in "${hw_repos_underlay_isolated[@]}"
do
    tryCreateLink $WORKSPACE_ROOT_DIR/sources/hw/underlay_isolated/$d  $WORKSPACE_ROOT_DIR/hw/underlay_isolated/src/$d
done

for d in "${hw_repos_underlay[@]}"
do
    tryCreateLink $WORKSPACE_ROOT_DIR/sources/hw/underlay/$d  $WORKSPACE_ROOT_DIR/hw/underlay/src/$d
done

for d in "${hw_repos_top[@]}"
do
    tryCreateLink $WORKSPACE_ROOT_DIR/sources/hw/top/$d  $WORKSPACE_ROOT_DIR/hw/top/src/$d
done

#
# underlay_isolated
#
cd $WORKSPACE_ROOT_DIR/hw/underlay_isolated
export OROCOS_TARGET=xenomai
catkin config --cmake-args -DENABLE_CORBA=ON -DCORBA_IMPLEMENTATION=OMNIORB -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_CORE_ONLY=ON   -DBUILD_SHARED_LIBS=ON   -DUSE_DOUBLE_PRECISION=ON -DBUILD_HELLOWORLD=OFF
catkin build
if [ $? -eq 0 ]; then
    echo "underlay_isolated build OK"
else
    printError "underlay_isolated build FAILED"
    exit 1
fi

cd $WORKSPACE_ROOT_DIR/sim/underlay_isolated
export OROCOS_TARGET=gnulinux
catkin config --cmake-args -DENABLE_CORBA=ON -DCORBA_IMPLEMENTATION=OMNIORB -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_CORE_ONLY=ON   -DBUILD_SHARED_LIBS=ON   -DUSE_DOUBLE_PRECISION=ON -DBUILD_HELLOWORLD=OFF
catkin build
if [ $? -eq 0 ]; then
    echo "underlay_isolated build OK"
else
    printError "underlay_isolated build FAILED"
    exit 1
fi

#
# underlay
#
cd $WORKSPACE_ROOT_DIR/hw/underlay
export OROCOS_TARGET=xenomai
catkin config --extend ../underlay_isolated/devel/ --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCATKIN_ENABLE_TESTING=OFF
catkin build
if [ $? -eq 0 ]; then
    echo "underlay build OK"
else
    printError "underlay build FAILED"
    exit 1
fi

cd $WORKSPACE_ROOT_DIR/sim/underlay
export OROCOS_TARGET=gnulinux
catkin config --extend ../underlay_isolated/devel/ --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCATKIN_ENABLE_TESTING=OFF
catkin build
if [ $? -eq 0 ]; then
    echo "underlay build OK"
else
    printError "underlay build FAILED"
    exit 1
fi

#
# top
#
cd $WORKSPACE_ROOT_DIR/hw/top
export OROCOS_TARGET=xenomai
catkin config --extend ../underlay/devel/ --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCATKIN_ENABLE_TESTING=OFF
catkin build
source devel/setup.bash

cd $WORKSPACE_ROOT_DIR/sim/top
export OROCOS_TARGET=gnulinux
catkin config --extend ../underlay/devel/ --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCATKIN_ENABLE_TESTING=OFF
catkin build
source devel/setup.bash

