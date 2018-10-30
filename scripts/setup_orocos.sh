#!/usr/bin/env bash

function usage {
	echo "usage: $0 <extend_directory> <script_dir> <build_directory> <build_type> [options] [-- catkin_build_opts]"
	echo "<build_type> can be one of (Debug|RelWithDebInfo|Release)"
	echo "Options:"
	echo "  -i [ --install ] arg  Install to directory"
	echo "catkin_build_opts are passed to 'catkin build' command"
}

function printError {
	RED='\033[0;31m'
	NC='\033[0m'
	echo -e "${RED}$1${NC}"
}

install_opt=""
catkin_build_opts=""

# parse command line arguments
POSITIONAL=()
while [[ $# -gt 0 ]]; do
	key="$1"
	case $key in
		-i|--install)
			install_opt="$2"
			shift 2
			if [ -z "$install_opt" ]; then
				printError "ERROR: wrong argument: install_opt"
				usage
				exit 1
			else
				install_opt="-i $install_opt --install"
			fi
		;;
		--)
			shift
			catkin_build_opts="$@"
			break
		;;
		*)
			# save it in an array for later
			POSITIONAL+=("$1")
			shift
		;;
	esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
	printError "Wrong argument - file or directory does not exist"
	usage
	exit 1
fi

extend_dir="$1"
script_dir="$2"
build_dir="$3"
build_type="$4"

### Prepare workspace
mkdir -p $build_dir/src
cd $build_dir
if [ ! -e ".rosinstall" ]; then
	wstool init
fi
wstool merge ${script_dir}/workspace_defs/common_orocos.rosinstall
wstool update

### Bugfixes/workarounds
# Fix OCL build on new GCC (warning: no-shift-negative-value)
sed -i 's/-Wextra -Wall -Werror/-Wextra -Wall -Werror -Wno-shift-negative-value/g' src/orocos/orocos_toolchain/ocl/lua/CMakeLists.txt

### Configure
CMAKE_ARGS="\
 -DCMAKE_BUILD_TYPE=${build_type}\
 -DENABLE_CORBA=ON\
 -DCORBA_IMPLEMENTATION=OMNIORB\
 -DBUILD_CORE_ONLY=ON\
 -DBUILD_SHARED_LIBS=ON\
 -DUSE_DOUBLE_PRECISION=ON\
 -DBUILD_HELLOWORLD=OFF\
 -DENABLE_SCREEN_TESTS=False\
"

catkin config $install_opt --extend $extend_dir --cmake-args $CMAKE_ARGS

### Build
catkin build $catkin_build_opts
