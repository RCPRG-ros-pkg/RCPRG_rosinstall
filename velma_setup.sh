#!/bin/bash


export LANG=en_US.UTF-8

# useful functions
function usage {
  echo "usage: $0 <version> directory"
  echo "The <version> can be one of the following:"
  svn ls https://github.com/RCPRG-ros-pkg/RCPRG_rosinstall.git/trunk/velma
  echo "latest"
  echo "latest_hw"
}

function printError {
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo -e "${RED}$1${NC}"
}

if [ $# -ne 2 ]; then
    echo "Wrong number of arguments."
    usage
    exit 1
fi

version="$1"

if [ -z "$2" ]; then
    echo "Wrong argument: $2"
    usage
    exit 1
fi

build_dir=$2

distro="$ROS_DISTRO"

if [ "$distro" != "kinetic" ]; then
    printError "ERROR: ROS kinetic setup.bash have to be sourced!"
    exit 1
fi

# the list of packages that should be installed
installed=(
"python-wstool"
"ruby-dev"
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
#"libfcl-dev"
"libqtwebkit-dev"
"libgts-dev"
#"ros-$distro-desktop"
"ros-$distro-polled-camera"
"ros-$distro-camera-info-manager"
"ros-$distro-control-toolbox"
"ros-$distro-controller-manager-msgs"
"ros-$distro-controller-manager"
"ros-$distro-urdfdom-py"
"ros-$distro-transmission-interface"
"ros-$distro-eigen-conversions"
"ros-$distro-octomap"
"ros-$distro-octomap-ros"
"ros-$distro-joint-limits-interface"
"ros-$distro-controller-interface"
"ros-$distro-ompl"
"ros-$distro-moveit-planners"
"ros-$distro-moveit-planners-ompl"
"ros-$distro-moveit-ros-planning-interface"
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

if [ ! -d $build_dir ]; then
  mkdir $build_dir
fi

FRI_DIR=`pwd`

cd $build_dir

WORKSPACE_ROOT_DIR=`pwd`

if [ ! -e ".rosinstall" ]; then
  wstool init
fi

# test
#cp common_orocos.rosinstall       /tmp/common_orocos.rosinstall
#cp common_agent.rosinstall        /tmp/common_agent.rosinstall
#cp common_velma.rosinstall        /tmp/common_velma.rosinstall
#cp gazebo7_2_dart.rosinstall      /tmp/gazebo7_2_dart.rosinstall
#cp velma_hw.rosinstall            /tmp/velma_hw.rosinstall

if [ "$version" == "latest" ]; then
    wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/common_orocos.rosinstall       -O /tmp/common_orocos.rosinstall
    wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/common_agent.rosinstall        -O /tmp/common_agent.rosinstall
    wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/common_velma.rosinstall        -O /tmp/common_velma.rosinstall
    wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/gazebo7_2_dart.rosinstall      -O /tmp/gazebo7_2_dart.rosinstall

    wstool merge /tmp/common_orocos.rosinstall
    wstool merge /tmp/common_agent.rosinstall
    wstool merge /tmp/common_velma.rosinstall
    wstool merge /tmp/gazebo7_2_dart.rosinstall
elif [ "$version" == "latest_hw" ]; then
    wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/common_orocos.rosinstall       -O /tmp/common_orocos.rosinstall
    wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/common_agent.rosinstall        -O /tmp/common_agent.rosinstall
    wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/common_velma.rosinstall        -O /tmp/common_velma.rosinstall
    wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/gazebo7_2_dart.rosinstall      -O /tmp/gazebo7_2_dart.rosinstall
    wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/velma_hw.rosinstall            -O /tmp/velma_hw.rosinstall

    wstool merge /tmp/common_orocos.rosinstall
    wstool merge /tmp/common_agent.rosinstall
    wstool merge /tmp/common_velma.rosinstall
    wstool merge /tmp/gazebo7_2_dart.rosinstall
    wstool merge /tmp/velma_hw.rosinstall
else
    wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/velma/$version       -O /tmp/velma.rosinstall

    if [ $? -ne 0 ]; then
        echo "Could not find version: $version"
        exit 4
    fi

    wstool merge /tmp/velma.rosinstall
fi

wstool update

# download package.xml for some packages
wget https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_dart-core.xml -O underlay_isolated/src/gazebo/dart/package.xml
wget https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_sdformat.xml  -O underlay_isolated/src/gazebo/sdformat/package.xml
wget https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_gazebo.xml    -O underlay_isolated/src/gazebo/gazebo/package.xml
wget https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_ign-math.xml  -O underlay_isolated/src/gazebo/ign-math/package.xml

if [ -d "underlay/src/lwr_hardware/kuka_lwr_fri/include/kuka_lwr_fri" ]; then
    # copy friComm.h
    cp -f $FRI_DIR/friComm.h underlay/src/lwr_hardware/kuka_lwr_fri/include/kuka_lwr_fri/
    if [ $? -eq 0 ]; then
        echo "cp friComm.h OK"
    else
        printError "cp friComm.h FAILED, fri dir: $FRI_DIR"
        exit 1
    fi
fi

#
# patch for gazebo -> set fsaa to 0
#

wget https://raw.githubusercontent.com/dudekw/gazebo-fsaa-patch/master/Camera.cc            -O $WORKSPACE_ROOT_DIR/underlay_isolated/src/gazebo/gazebo/gazebo/rendering/Camera.cc

#
# underlay_isolated
#
cd $WORKSPACE_ROOT_DIR/underlay_isolated
catkin config --cmake-args -DENABLE_CORBA=ON -DCORBA_IMPLEMENTATION=OMNIORB -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_CORE_ONLY=ON   -DBUILD_SHARED_LIBS=ON   -DUSE_DOUBLE_PRECISION=ON -DENABLE_MQUEUE=ON -DBUILD_HELLOWORLD=OFF -DENABLE_TESTS_COMPILATION=False -DENABLE_SCREEN_TESTS=False
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
cd $WORKSPACE_ROOT_DIR/underlay
catkin config --extend ../underlay_isolated/devel/ --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCATKIN_ENABLE_TESTING=OFF -DENABLE_MQUEUE=ON
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
cd $WORKSPACE_ROOT_DIR/top
catkin config --extend ../underlay/devel/ --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCATKIN_ENABLE_TESTING=OFF -DENABLE_MQUEUE=ON
catkin build
source devel/setup.bash

