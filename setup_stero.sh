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

if [ $# -ne 2 ]; then
    printError "Wrong number of arguments."
    usage
    exit 1
fi

if [ -z "$1" ]; then
    printError "Wrong argument: $1"
    usage
    exit 1
fi

build_dir="$1"
build_type="$2"

if [ "$build_type" != "Debug" ] && [ "$build_type" != "RelWithDebInfo" ] && [ "$build_type" != "Release" ]; then
    printError "ERROR: wrong argument: build_type=$build_type"
    usage
    exit 1
fi

script_dir=`pwd`

if [ ! -d "$build_dir" ]; then
  mkdir -p "$build_dir"
fi
if [ ! -d "$install_dir" ]; then
  mkdir -p "$install_dir"
fi

cd "$build_dir"
build_dir=`pwd`

# test
#cp ~/code/RCPRG_rosinstall/setup_orocos_gazebo.sh     /tmp/setup_orocos_gazebo.sh
#cp ~/code/RCPRG_rosinstall/setup_fabric.sh            /tmp/setup_fabric.sh
#cp ~/code/RCPRG_rosinstall/setup_velma_os.sh          /tmp/setup_velma_os.sh
#cp ~/code/RCPRG_rosinstall/setup_elektron.sh          /tmp/setup_elektron.sh

wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/setup_orocos_gazebo.sh     -O /tmp/setup_orocos_gazebo.sh
wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/setup_fabric.sh            -O /tmp/setup_fabric.sh
wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/setup_velma_os.sh          -O /tmp/setup_velma_os.sh
wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/setup_elektron.sh          -O /tmp/setup_elektron.sh

chmod 755 /tmp/setup_orocos_gazebo.sh
chmod 755 /tmp/setup_fabric.sh
chmod 755 /tmp/setup_velma_os.sh
chmod 755 /tmp/setup_elektron.sh

if [ -z "$install_dir" ]; then
    echo "do not install"
    cd "$script_dir"
    bash /tmp/setup_orocos_gazebo.sh "$build_dir/ws_gazebo_orocos" "$build_type" -j "$num_threads"
    if [ $? -ne 0 ]; then
        exit 1
    fi
    cd "$script_dir"
    bash /tmp/setup_fabric.sh "$build_dir/ws_gazebo_orocos/devel" "$build_dir/ws_fabric" "$build_type" -j "$num_threads"
    if [ $? -ne 0 ]; then
        exit 1
    fi
    cd "$script_dir"
    bash /tmp/setup_velma_os.sh "$build_dir/ws_fabric/devel" "$build_dir/ws_velma" "$build_type" -j "$num_threads"
    if [ $? -ne 0 ]; then
        exit 1
    fi
    cd "$script_dir"
    bash /tmp/setup_elektron.sh "$build_dir/ws_fabric/devel" "$build_dir/ws_elektron" "$build_type"
    if [ $? -ne 0 ]; then
        exit 1
    fi
else
    cd "$script_dir"
    cd "$install_dir"
    install_dir=`pwd`

    echo "install to $install_dir"
    cd "$script_dir"
    bash /tmp/setup_orocos_gazebo.sh "$build_dir/ws_gazebo_orocos" "$build_type" -i "$install_dir/ws_gazebo_orocos" -j "$num_threads"
    if [ $? -ne 0 ]; then
        exit 1
    fi
    cd "$script_dir"
    bash /tmp/setup_fabric.sh "$install_dir/ws_gazebo_orocos/install" "$build_dir/ws_fabric" "$build_type" -i "$install_dir/ws_fabric" -j "$num_threads"
    if [ $? -ne 0 ]; then
        exit 1
    fi
    cd "$script_dir"
    bash /tmp/setup_velma_os.sh "$install_dir/ws_fabric/install" "$build_dir/ws_velma" "$build_type" -i "$install_dir/ws_velma" -j "$num_threads"
    if [ $? -ne 0 ]; then
        exit 1
    fi
    cd "$script_dir"
    bash /tmp/setup_elektron.sh "$install_dir/ws_fabric/install" "$build_dir/ws_elektron" "$build_type" -i "$install_dir/ws_elektron"
    if [ $? -ne 0 ]; then
        exit 1
    fi
fi

