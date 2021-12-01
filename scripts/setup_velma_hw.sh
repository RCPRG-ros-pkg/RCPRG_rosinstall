#!/usr/bin/env bash

function usage {
	echo "usage: $0 <extend_directory> <script_dir> <build_directory> <build_type> [options] [-- catkin_build_opts]"
	echo "<build_type> can be one of (Debug|RelWithDebInfo|Release)"
	echo "Options:"
	echo "  -i [ --install ] arg   Install to directory"
	echo "  -w [ --velma-hw ] Install packages for hw support"
	echo "  -g [ --velma-sim-gazebo ] Install packages for simulation in Gazebo"
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
		-w|--velma-hw)
			velma_hw=1
			shift
		;;
		-g|--velma-sim-gazebo)
			velma_sim_gazebo=1
			shift
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

FRI_DIR=$script_dir

### Prepare workspace
mkdir -p $build_dir/src
cd $build_dir
if [ ! -e ".rosinstall" ]; then
	wstool init
fi
wstool merge ${script_dir}/workspace_defs/velma_hw.rosinstall
if [ $? -ne 0 ]; then
    printError "The command wstool merge terminated with error. Terminating the setup script."
    exit 2
fi
wstool update
if [ $? -ne 0 ]; then
    printError "The command wstool update terminated with error. Terminating the setup script."
    exit 3
fi

### Bugfixes/workarounds
# Add closed-source friComm header for operating on real Kuka LWR hardware
if [ -d "$build_dir/src/lwr_hardware/kuka_lwr_fri/include/kuka_lwr_fri" ]; then
	# copy friComm.h
	cp -f "$FRI_DIR/friComm.h" "$build_dir/src/lwr_hardware/kuka_lwr_fri/include/kuka_lwr_fri/"
	if [ $? -eq 0 ]; then
		echo "cp friComm.h OK"
	else
		printError "cp friComm.h FAILED, fri dir: $FRI_DIR"
		exit 4
	fi
fi

### Config
CMAKE_ARGS="\
 -DCMAKE_BUILD_TYPE=${build_type}\
 -DCATKIN_ENABLE_TESTING=OFF\
"

catkin config $install_opt --extend $extend_dir --cmake-args $CMAKE_ARGS

### Build
catkin build $catkin_build_opts
