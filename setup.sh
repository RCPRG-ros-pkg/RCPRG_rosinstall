#!/usr/bin/env bash

function usage {
	echo "usage: $0 [build_directory] [build_type] [options]"
	echo "  [build_directory] defaults to 'ws'"
	echo "  [build_type] can be one of (Debug|RelWithDebInfo|Release), defaults to 'RelWithDebInfo'"
	echo "Options:"
	echo "  -i [ --install ] arg   Install to directory"
}

function printError {
	RED='\033[0;31m'
	NC='\033[0m' # No Color
	echo -e "${RED}$1${NC}"
}

function buildWorkspace {
	name=$1
	dependency=$2
	build_type=$3
	root_dir=$4
	build_dir=$5
	install_dir=$6

	setup_script="scripts/setup_${name}.sh"
	dep_dir=""
	if [ ! -z dependency ]; then
		if [ -z install_dir ]; then
			dep_dir="${build_dir}/ws_${dependency}/devel"
		else
			dep_dir="${install_dir}/ws_${dependency}/install"
		fi
	fi
	ws_dir="${build_dir}/ws_${name}"
	install=""
	if [ ! -z install_dir ]; then
		install="-i ${install_dir}/ws_${name}/install"
	fi

	cd $root_dir
	bash $setup_script $dep_dir $ws_dir $build_type $install
}

install_dir=""

# parse command line arguments
POSITIONAL=()
while [[ $# -gt 0 ]]; do
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
	build_dir="ws"
	build_type="RelWithDebInfo"
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
if [ ! -z "$install_dir" ]; then
	mkdir -p "$install_dir"
	cd "$install_dir"
	install_dir=`pwd`
else
	install_dir=$build_dir
fi

### Build workspaces
# buildWorkspace "gazebo" "" $build_type $script_dir $build_dir $install_dir
# buildWorkspace "orocos" "gazebo" $build_type $script_dir $build_dir $install_dir
# buildWorkspace "fabric" "orocos" $build_type $script_dir $build_dir $install_dir
buildWorkspace "velma_os" "fabric" $build_type $script_dir $build_dir $install_dir
