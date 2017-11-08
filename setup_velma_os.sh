#!/bin/bash

export LANG=en_US.UTF-8

# useful functions
function usage {
  echo "usage: $0 <build_directory> <build_type> [options]"
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

if [ "$build_type" != "Debug" ] && [ "$build_type" != "RelWithDebInfo" ] && [ "$build_type" != "Release" ]; then
    printError "ERROR: wrong argument: build_type=$build_type"
    usage
    exit 1
fi

echo "checking dependencies and conflicts..."
#cp ~/code/RCPRG_rosinstall/setup_orocos_gazebo_deps /tmp/setup_orocos_gazebo_deps
#cp ~/code/RCPRG_rosinstall/setup_orocos_gazebo_conflicts /tmp/setup_orocos_gazebo_conflicts
wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/setup_velma_os_deps            -O /tmp/setup_velma_os_deps
wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/check_deps.sh                  -O /tmp/check_deps.sh
chmod 755 /tmp/check_deps.sh

bash /tmp/check_deps.sh /tmp/setup_velma_os_deps
error=$?
if [ ! "$error" == "0" ]; then
    printError "error in dependencies: $error"
    exit 1
fi

echo "dependencies OK"

if [ ! -d $build_dir ]; then
  mkdir $build_dir
fi

FRI_DIR=`pwd`

cd $build_dir

if [ ! -e ".rosinstall" ]; then
  wstool init
fi

wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/common_velma.rosinstall        -O /tmp/common_velma.rosinstall

wstool merge /tmp/common_velma.rosinstall

wstool update

if [ -d "$build_dir/src/lwr_hardware/kuka_lwr_fri/include/kuka_lwr_fri" ]; then
    # copy friComm.h
    cp -f "$FRI_DIR/friComm.h" "$build_dir/src/lwr_hardware/kuka_lwr_fri/include/kuka_lwr_fri/"
    if [ $? -eq 0 ]; then
        echo "cp friComm.h OK"
    else
        printError "cp friComm.h FAILED, fri dir: $FRI_DIR"
        exit 1
    fi
fi

if [ -z "$install_dir" ]; then
    catkin config --extend "$extend_dir" --cmake-args -DCMAKE_BUILD_TYPE="$build_type" -DCATKIN_ENABLE_TESTING=OFF
else
    catkin config -i "$install_dir" --install --extend "$extend_dir" --cmake-args -DCMAKE_BUILD_TYPE="$build_type" -DCATKIN_ENABLE_TESTING=OFF
fi
catkin build --no-status -j "$num_threads"

