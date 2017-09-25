#!/bin/bash

export LANG=en_US.UTF-8

# useful functions
function usage {
  echo "usage: $0 extend_directory build_directory build_type [-i install_directory]"
}

function printError {
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo -e "${RED}$1${NC}"
}

install_dir=""

if [ $# -eq 5 ] && [ "$4" == "-i" ]; then
    install_dir="$5"
elif [ $# -ne 3 ]; then
    echo "Wrong number of arguments."
    usage
    exit 1
fi

if [ -z "$1" ]; then
    echo "Wrong argument: $1"
    usage
    exit 1
fi

extend_dir="$1"
build_dir="$2"
build_type="$3"

distro="$ROS_DISTRO"

if [ "$distro" != "kinetic" ]; then
    printError "ERROR: ROS kinetic setup.bash have to be sourced!"
    exit 1
fi

# the list of packages that should be installed
installed=(
# elektron-specific
"ros-$distro-joint-state-controller"
"ros-$distro-diff-drive-controller"
"ros-$distro-effort-controllers"
"ros-$distro-position-controllers"
"ros-$distro-scan-tools"
"ros-$distro-yocs-cmd-vel-mux"
"ros-$distro-navigation"
"ros-$distro-gmapping"
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

if [ "$error" = true ]; then
    echo "Please install/uninstall the listed packages"
    echo "To install libccd please see http://askubuntu.com/questions/664101/dependency-in-ppa"
    exit 1
fi

if [ ! -d $build_dir ]; then
  mkdir $build_dir
fi

cd $build_dir


if [ ! -e ".rosinstall" ]; then
  wstool init
fi

wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/elektron.rosinstall            -O /tmp/elektron.rosinstall

wstool merge /tmp/elektron.rosinstall

wstool update

# unregister submodules for hw camera support and for Rapp
cd $build_dir/src/elektron
git submodule deinit elektron_apps/elektron-rapps netusb_camera_driver rapp-api-elektron
cd $build_dir

if [ -z "$install_dir" ]; then
    catkin config --extend "$extend_dir" --cmake-args -DCMAKE_BUILD_TYPE="$build_type" -DCATKIN_ENABLE_TESTING=OFF
else
    catkin config -i "$install_dir/install" --install --extend "$extend_dir" --cmake-args -DCMAKE_BUILD_TYPE="$build_type" -DCATKIN_ENABLE_TESTING=OFF
fi
catkin build

