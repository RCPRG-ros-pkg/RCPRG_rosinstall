#!/usr/bin/env bash

function usage {
	echo "usage: $0 [build_directory] [build_type] [options]"
#	echo "  [build_directory] defaults to 'ws'"
	echo "  [build_type] can be one of (Debug|RelWithDebInfo|Release), defaults to 'RelWithDebInfo'"
	echo "Options:"
	echo "  -i [ --install ] arg   Install to directory"
	echo "  -j arg                 Use 'arg' CPU cores"
}

function printError {
	RED='\033[0;31m'
	NC='\033[0m' # No Color
	echo -e "${RED}$1${NC}"
}

install_dir=""
num_cores=""

# parse command line arguments
POSITIONAL=()
while [[ $# -gt 0 ]]; do
	key="$1"

	case $key in
		-i|--install)
			install_dir="$2"
			shift 2
			if [ -z "$install_dir" ]; then
				printError "ERROR: wrong argument: install_dir"
				usage
				exit 1
			fi
		;;
		-j)
			num_cores="$2"
			shift 2
		;;
		*)
			POSITIONAL+=("$1") # save it in an array for later
			shift # past argument
		;;
	esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

### Directory arguments
build_dir=""
build_type=""
if [ $# -eq 2 ]; then
	build_dir="$1"
	build_type="$2"
fi
if [ $# -eq 1 ]; then
	build_dir="$1"
	build_type="RelWithDebInfo"
fi
if [ $# -eq 0 ]; then
#	build_dir="ws"
#	build_type="RelWithDebInfo"
	usage
	exit 1
fi
if [ "$build_type" != "Debug" ] && [ "$build_type" != "RelWithDebInfo" ] && [ "$build_type" != "Release" ]; then
	printError "ERROR: wrong argument: build_type=$build_type"
	usage
	exit 1
fi

### Dependencies
bash scripts/check_deps.sh workspace_defs/main_dependencies
error=$?
if [ ! "$error" == "0" ]; then
	printError "error in dependencies: $error"
	exit 1
fi

### ROS check
if [ "$ROS_DISTRO" != "melodic" ]; then
    printError "ERROR: ROS melodic setup.bash have to be sourced!"
    exit 1
fi

### Paths
# Get absolute path for script root, build and install directories
export script_dir=`pwd`
mkdir -p "$build_dir"
cd "$build_dir"
build_dir=`pwd`

if [ ! -z "$num_cores" ]; then
	num_cores_str="-j $num_cores"
else
	num_cores_str=""
fi

if [ ! -z "$install_dir" ]; then
	mkdir -p "$install_dir"
	cd "$install_dir"
	install_dir=`pwd`
    install_dir_gazebo="$install_dir/ws_gazebo"
	install_dir_orocos="$install_dir/ws_orocos"
	install_dir_fabric="$install_dir/ws_fabric"
	install_dir_velma_os_str="-i $install_dir/ws_velma_os"
else
	install_dir_gazebo="$build_dir/ws_gazebo/install"
	install_dir_orocos="$build_dir/ws_orocos/install"
	install_dir_fabric="$build_dir/ws_fabric/install"
	install_dir_velma_os_str=""
fi

cd "$build_dir"

# build in home folder, without install of the highest ws
echo "bash $script_dir/scripts/setup_gazebo.sh /opt/ros/melodic $build_dir/ws_gazebo $build_type -i $install_dir_gazebo $num_cores_str"
bash $script_dir/scripts/setup_gazebo.sh /opt/ros/melodic $build_dir/ws_gazebo $build_type -i $install_dir_gazebo $num_cores_str
if [ $? -ne 0 ]; then
	printError "The command finished with error. Terminating the setup script."
	exit 2
fi

echo "bash $script_dir/scripts/setup_orocos.sh $install_dir_gazebo $build_dir/ws_orocos $build_type -i $install_dir_orocos $num_cores_str"
bash $script_dir/scripts/setup_orocos.sh $install_dir_gazebo $build_dir/ws_orocos $build_type -i $install_dir_orocos $num_cores_str
if [ $? -ne 0 ]; then
	printError "The command finished with error. Terminating the setup script."
	exit 2
fi

echo "bash $script_dir/scripts/setup_fabric.sh $install_dir_orocos $build_dir/ws_fabric $build_type -i $install_dir_fabric $num_cores_str"
bash $script_dir/scripts/setup_fabric.sh $install_dir_orocos $build_dir/ws_fabric $build_type -i $install_dir_fabric $num_cores_str
if [ $? -ne 0 ]; then
	printError "The command finished with error. Terminating the setup script."
	exit 2
fi

echo "bash $script_dir/scripts/setup_velma_os.sh $install_dir_fabric $build_dir/ws_velma_os $build_type $install_dir_velma_os_str $num_cores_str"
bash $script_dir/scripts/setup_velma_os.sh $install_dir_fabric $build_dir/ws_velma_os $build_type $install_dir_velma_os_str $num_cores_str

