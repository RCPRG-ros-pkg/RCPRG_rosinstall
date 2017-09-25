#!/bin/bash

export LANG=en_US.UTF-8

# useful functions
function usage {
  echo "usage: $0 build_directory build_type [-i install_directory]"
}

function printError {
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo -e "${RED}$1${NC}"
}

install_dir=""

if [ $# -eq 4 ] && [ "$3" == "-i" ]; then
    install_dir=$4
elif [ $# -ne 2 ]; then
    echo "Wrong number of arguments."
    usage
    exit 1
fi

if [ -z "$1" ]; then
    echo "Wrong argument: $1"
    usage
    exit 1
fi

build_dir="$1"
build_type="$2"

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
"libqtwebkit-dev"
"libgts-dev"
"unzip"
"ros-$distro-desktop"
"ros-$distro-polled-camera"
"ros-$distro-camera-info-manager"
"ros-$distro-control-toolbox"
"ros-$distro-controller-manager-msgs"
"ros-$distro-controller-manager"
"ros-$distro-urdfdom-py"
"ros-$distro-transmission-interface"
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

cd $build_dir

WORKSPACE_ROOT_DIR=`pwd`

if [ ! -e ".rosinstall" ]; then
  wstool init
fi

wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/common_orocos.rosinstall       -O /tmp/common_orocos.rosinstall
wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/gazebo7_2_dart.rosinstall      -O /tmp/gazebo7_2_dart.rosinstall

wstool merge /tmp/common_orocos.rosinstall
wstool merge /tmp/gazebo7_2_dart.rosinstall

wstool update

#not working hg repo fix
wget https://bitbucket.org/osrf/gazebo/get/gazebo7_7.2.0.zip                                                -O /tmp/gazebo7_2.zip
if [ $? -ne 0 ]; then
    printError "could not download gazebo zip file"
    exit 1
fi
rm -rf src/gazebo/gazebo
unzip -q -o -d src/gazebo /tmp/gazebo7_2.zip
mv -v src/gazebo/osrf-gazebo-baa1cf34ff0e src/gazebo/gazebo
if [ $? -ne 0 ]; then
    printError "an unknown error: gazebo zip file"
    exit 1
fi

# download package.xml for some packages
wget https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_dart-core.xml -O src/gazebo/dart/package.xml
wget https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_sdformat.xml  -O src/gazebo/sdformat/package.xml
wget https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_gazebo.xml    -O src/gazebo/gazebo/package.xml
wget https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_ign-math.xml  -O src/gazebo/ign-math/package.xml

#
# patch for gazebo -> set fsaa to 0
#
wget https://raw.githubusercontent.com/dudekw/gazebo-fsaa-patch/master/Camera.cc            -O $WORKSPACE_ROOT_DIR/src/gazebo/gazebo/gazebo/rendering/Camera.cc

if [ -z "$install_dir" ]; then
    catkin config --cmake-args -DENABLE_CORBA=ON -DCORBA_IMPLEMENTATION=OMNIORB -DCMAKE_BUILD_TYPE="$build_type" -DBUILD_CORE_ONLY=ON   -DBUILD_SHARED_LIBS=ON   -DUSE_DOUBLE_PRECISION=ON -DBUILD_HELLOWORLD=OFF -DENABLE_TESTS_COMPILATION=False -DENABLE_SCREEN_TESTS=False
else
    catkin config -i "$install_dir/install" --install --cmake-args -DENABLE_CORBA=ON -DCORBA_IMPLEMENTATION=OMNIORB -DCMAKE_BUILD_TYPE="$build_type" -DBUILD_CORE_ONLY=ON   -DBUILD_SHARED_LIBS=ON   -DUSE_DOUBLE_PRECISION=ON -DBUILD_HELLOWORLD=OFF -DENABLE_TESTS_COMPILATION=False -DENABLE_SCREEN_TESTS=False
fi
catkin build
if [ $? -eq 0 ]; then
    echo "build OK"
else
    printError "build FAILED"
    exit 1
fi

exit 0

