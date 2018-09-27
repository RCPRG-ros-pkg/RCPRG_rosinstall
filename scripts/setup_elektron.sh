#!/usr/bin/env bash

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

if [ "$distro" != "melodic" ]; then
    printError "ERROR: ROS melodic setup.bash have to be sourced!"
    exit 1
fi

echo "checking dependencies and conflicts..."
#cp ~/code/RCPRG_rosinstall/setup_elektron_deps /tmp/setup_elektron_deps
#cp ~/code/RCPRG_rosinstall/setup_elektron_conflicts /tmp/setup_elektron_conflicts
wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/setup_elektron_deps       -O /tmp/setup_elektron_deps
wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/check_deps.sh                  -O /tmp/check_deps.sh
chmod 755 /tmp/check_deps.sh

bash /tmp/check_deps.sh /tmp/setup_elektron_deps
error=$?
if [ ! "$error" == "0" ]; then
    printError "error in dependencies: $error"
    exit 1
fi

echo "dependencies OK"

if [ ! -d $build_dir ]; then
  mkdir $build_dir
fi

cd $build_dir
build_dir=`pwd`

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
    catkin config -i "$install_dir" --install --extend "$extend_dir" --cmake-args -DCMAKE_BUILD_TYPE="$build_type" -DCATKIN_ENABLE_TESTING=OFF
fi
catkin build --no-status

# Patch for gmapping install BUG fix
# sudo wget https://raw.githubusercontent.com/gavanderhoorn/slam_gmapping/hydro-devel/gmapping/nodelet_plugins.xml              -O /opt/ros/kinetic/share/gmapping/nodelet_plugins.xml

