#!/usr/bin/env bash

function usage {
  echo "usage: $0 <extend_directory> <build_directory> <build_type> [options]"
  echo "<build_type> can be one of (Debug|RelWithDebInfo|Release)"
  echo "Options:"
  echo "  -i [ --install ] arg   Install to directory"
}

function printError {
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo -e "${RED}$1${NC}"
}

# The following code is a workaround for bug in FindUUID in ROS melodic.
#TODO: check status of the bug and update the script when resolved
if [ -f /opt/ros/melodic/share/cmake_modules/cmake/Modules/FindUUID.cmake ]; then
	printError "ERROR: file /opt/ros/melodic/share/cmake_modules/cmake/Modules/FindUUID.cmake causes linker error (/usr/bin/ld: cannot find -lUUID::UUID). You should remove it using command:"
	printError "sudo rm /opt/ros/melodic/share/cmake_modules/cmake/Modules/FindUUID.cmake"
 	exit 3
fi

install_dir=""

# parse command line arguments
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -i|--install)
    install_dir="$2"
    shift # past argument
    shift # past value
    if [ -z "$install_dir" ]; then
        printError "ERROR: wrong argument: install_dir"
        usage
        exit 1
    fi
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ $# -ne 3 ]; then
    printError "Wrong number of arguments."
    usage
    exit 1
fi

if [ -z "$1" ]; then
    printError "Wrong argument: $1"
    usage
    exit 1
fi

extend_dir="$1"
build_dir="$2"
build_type="$3"

mkdir -p $build_dir/src
cd $build_dir
if [ ! -e ".rosinstall" ]; then
  wstool init
fi

wstool merge ${script_dir}/workspace_defs/common_fabric.rosinstall
wstool update

echo $extend_dir
echo $build_type
echo $install_dir

if [ -z "$install_dir" ]; then
    catkin config --extend "$extend_dir" --cmake-args -DCMAKE_BUILD_TYPE="$build_type" -DCATKIN_ENABLE_TESTING=OFF
else
    catkin config -i "$install_dir" --install --extend "$extend_dir" --cmake-args -DCMAKE_BUILD_TYPE="$build_type" -DCATKIN_ENABLE_TESTING=OFF
fi

catkin build
