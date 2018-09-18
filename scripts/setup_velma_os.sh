#!/usr/bin/env bash
echo "valma install"
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


mkdir -p $build_dir/src
FRI_DIR=`pwd`
cd $build_dir
if [ ! -e ".rosinstall" ]; then
  wstool init
fi

wstool merge ${script_dir}/workspace_defs/common_velma.rosinstall
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
    echo "extend"
    echo $extend_dir
    catkin config --extend "$extend_dir" --cmake-args -DCMAKE_BUILD_TYPE="$build_type" -DCATKIN_ENABLE_TESTING=OFF
else
    echo "extend_dir install"
    echo $extend_dir
    catkin config -i "$install_dir" --install --extend "$extend_dir" --cmake-args -DCMAKE_BUILD_TYPE="$build_type" -DCATKIN_ENABLE_TESTING=OFF
fi
catkin build

