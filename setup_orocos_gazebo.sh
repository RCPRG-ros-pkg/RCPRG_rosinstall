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

distro="$ROS_DISTRO"

if [ "$distro" != "kinetic" ]; then
    printError "ERROR: ROS kinetic setup.bash have to be sourced!"
    exit 1
fi

echo "checking dependencies and conflicts..."
#cp ~/code/RCPRG_rosinstall/setup_orocos_gazebo_deps /tmp/setup_orocos_gazebo_deps
#cp ~/code/RCPRG_rosinstall/setup_orocos_gazebo_conflicts /tmp/setup_orocos_gazebo_conflicts
wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/setup_orocos_gazebo_deps       -O /tmp/setup_orocos_gazebo_deps
wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/setup_orocos_gazebo_conflicts  -O /tmp/setup_orocos_gazebo_conflicts
wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/check_deps.sh                  -O /tmp/check_deps.sh
chmod 755 /tmp/check_deps.sh

bash /tmp/check_deps.sh /tmp/setup_orocos_gazebo_deps /tmp/setup_orocos_gazebo_conflicts
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

WORKSPACE_ROOT_DIR=`pwd`

if [ ! -e ".rosinstall" ]; then
  wstool init
fi

wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/common_orocos.rosinstall       -O /tmp/common_orocos.rosinstall
wget https://raw.githubusercontent.com/RCPRG-ros-pkg/RCPRG_rosinstall/master/gazebo7_dart.rosinstall        -O /tmp/gazebo7_dart.rosinstall

wstool merge /tmp/common_orocos.rosinstall
wstool merge /tmp/gazebo7_dart.rosinstall

wstool update

#not working hg repo fix
wget https://bitbucket.org/osrf/gazebo/get/gazebo7_7.8.1.zip                                                -O /tmp/gazebo7_8.zip
if [ $? -ne 0 ]; then
    printError "could not download gazebo zip file"
    exit 1
fi
rm -rf src/gazebo/gazebo
unzip -q -o -d src/gazebo /tmp/gazebo7_8.zip
mv -v src/gazebo/osrf-gazebo-a24b331f8ebf src/gazebo/gazebo
if [ $? -ne 0 ]; then
    printError "an unknown error: gazebo zip file"
    exit 1
fi

# download package.xml for some packages
wget https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_dart-core.xml -O src/gazebo/dart/package.xml
wget https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_sdformat.xml  -O src/gazebo/sdformat/package.xml
wget https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_gazebo.xml    -O src/gazebo/gazebo/package.xml
wget https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_ign-math.xml  -O src/gazebo/ign-math/package.xml

if [ -z "$install_dir" ]; then
    catkin config --cmake-args -DENABLE_CORBA=ON -DCORBA_IMPLEMENTATION=OMNIORB -DCMAKE_BUILD_TYPE="$build_type" -DBUILD_CORE_ONLY=ON   -DBUILD_SHARED_LIBS=ON   -DUSE_DOUBLE_PRECISION=ON -DBUILD_HELLOWORLD=OFF -DENABLE_TESTS_COMPILATION=False -DENABLE_SCREEN_TESTS=False
else
    catkin config -i "$install_dir" --install --cmake-args -DENABLE_CORBA=ON -DCORBA_IMPLEMENTATION=OMNIORB -DCMAKE_BUILD_TYPE="$build_type" -DBUILD_CORE_ONLY=ON   -DBUILD_SHARED_LIBS=ON   -DUSE_DOUBLE_PRECISION=ON -DBUILD_HELLOWORLD=OFF -DENABLE_TESTS_COMPILATION=False -DENABLE_SCREEN_TESTS=False
fi
catkin build --no-status -j "$num_threads"
#if [ $? -eq 0 ]; then
#    echo "build OK"
#else
#    printError "build FAILED"
#    exit 1
#fi
#exit 0

