#!/usr/bin/env bash

function usage {
  echo "usage: $0 <extend_directory> <build_directory> <build_type> [options]"
  echo "<build_type> can be one of (Debug|RelWithDebInfo|Release)"
  echo "Options:"
  echo "  -i [ --install ] arg   Install to directory"
  echo "  -j arg (=4)            Pass -j arg option to make, i.e. number of threads"
}

function printError {
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo -e "${RED}$1${NC}"
}

install_dir=""
num_threads=4

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
    -j)
    num_threads="$2"
    shift # past argument
    shift # past value
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

mkdir -p $build_dir
cd $build_dir

WORKSPACE_ROOT_DIR=`pwd`

if [ ! -e ".rosinstall" ]; then
  wstool init
fi

wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/common_agent.rosinstall -O /tmp/common_agent.rosinstall
wstool merge /tmp/common_agent.rosinstall
wstool update

if [ -z "$install_dir" ]; then
    catkin config --extend "$extend_dir" --cmake-args -DCMAKE_BUILD_TYPE="$build_type" -DCATKIN_ENABLE_TESTING=OFF
else
    catkin config -i "$install_dir" --install --extend "$extend_dir" --cmake-args -DCMAKE_BUILD_TYPE="$build_type" -DCATKIN_ENABLE_TESTING=OFF
fi
catkin build --no-status -j "$num_threads"
#if [ $? -eq 0 ]; then
#    echo "build OK"
#else
#    printError "build FAILED"
#    exit 1
#fi

#### FIX
# src/rtt_gazebo/rtt_gazebo_examples/src/default_gazebo_component.cpp:98
# src/rtt_gazebo/rtt_gazebo_system/src/rtt_system_plugin.cpp:114
# GetSimTime() -> SimTime()

#### FIX2
# build/rtt_gazebo_system/CMakeFiles/rtt_gazebo_system.dir/link.txt
# -lUUID::UUID -> -luuid
