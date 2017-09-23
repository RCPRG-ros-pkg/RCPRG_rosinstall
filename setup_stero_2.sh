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

script_dir=`pwd`

if [ ! -d $build_dir ]; then
  mkdir $build_dir
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

if [ -n $install_dir ]; then
    echo "do not install"
    cd "$script_dir"
    bash /tmp/setup_orocos_gazebo.sh "$build_dir/ws_gazebo_orocos" "$build_type"
    if [ $? -ne 0 ]; then
        exit 1
    fi
    cd "$script_dir"
    bash /tmp/setup_fabric.sh "$build_dir/ws_gazebo_orocos/devel" "$build_dir/ws_fabric" "$build_type"
    if [ $? -ne 0 ]; then
        exit 1
    fi
    cd "$script_dir"
    bash /tmp/setup_velma_os.sh "$build_dir/ws_fabric/devel" "$build_dir/ws_velma" "$build_type"
    if [ $? -ne 0 ]; then
        exit 1
    fi
    cd "$script_dir"
    bash /tmp/setup_elektron.sh "$build_dir/ws_fabric/devel" "$build_dir/ws_elektron" "$build_type"
    if [ $? -ne 0 ]; then
        exit 1
    fi
else
    echo "install to $install_dir"
    cd "$script_dir"
    bash /tmp/setup_orocos_gazebo.sh "$build_dir/ws_gazebo_orocos" "$build_type" -i "$install_dir/ws_gazebo_orocos"
    if [ $? -ne 0 ]; then
        exit 1
    fi
    cd "$script_dir"
    bash /tmp/setup_fabric.sh "$install_dir/ws_gazebo_orocos/install" "$build_dir/ws_fabric" "$build_type" -i "$install_dir/ws_fabric"
    if [ $? -ne 0 ]; then
        exit 1
    fi
    cd "$script_dir"
    bash /tmp/setup_velma_os.sh "$install_dir/ws_fabric/install" "$build_dir/ws_velma" "$build_type" -i "$install_dir/ws_velma"
    if [ $? -ne 0 ]; then
        exit 1
    fi
    cd "$script_dir"
    bash /tmp/setup_elektron.sh "$install_dir/ws_fabric/install" "$build_dir/ws_elektron" "$build_type" -i "$install_dir/ws_elektron"
    if [ $? -ne 0 ]; then
        exit 1
    fi
fi

