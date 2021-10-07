#!/usr/bin/env bash

function usage {
	echo "usage: $0 dependency_on [options] [-- catkin_build_opts]"
	echo "Options:"
	echo "  -h [ --help ]            Display this message and exit"
    echo "  -x [ --extend ]          Extend workspace: path to parent workspace, typically /opt/ros/melodic"
	echo "  -d [ --build-dir ] arg   Build directory, defaults to 'build'"
	echo "  -b [ --build-type ] arg  Build type, can be one of (Debug|RelWithDebInfo|Release), defaults to 'RelWithDebInfo'"
	echo "  -i [ --install ] arg     Install to directory"
	echo "  -F [ --fakechroot ]      build in fake root directory"
	echo "  -g [ --gazebo ]          build gazebo workspace"
	echo "  -t [ --tiago ]           build tiago workspace"
	echo "  -o [ --orocos ]          build orocos workspace"
	echo "  -f [ --fabric ]          build fabric workspace"
	echo "  -v [ --velma ]           build velma workspace"
	echo "  -w [ --velma-hw ]        build velma HW workspace"
	echo "catkin_build_opts are passed to 'catkin build' command"
}

function printError {
	RED='\033[0;31m'
	NC='\033[0m'
	echo -e "${RED}$1${NC}"
}

function buildWorkspace {
	name_arg=$1
	dependency_arg=$2
	build_type_arg=$3
	script_dir_arg=$4
	build_dir_arg=$5
	install_dir_arg=$6
	devel_space_only_arg=$7
	additional_options=$8
	shift 8

	setup_script="${script_dir_arg}/scripts/setup_${name_arg}.sh"
    dep_dir="$dependency_arg"
	#dep_dir="/opt/ros/melodic"
	#if [ ! -z $dependency_arg ]; then
	#	if [ ! -z $install_dir_arg ]; then
	#		dep_dir="${install_dir_arg}/ws_${dependency_arg}"
	#	else
	#		if [ $devel_space_only_arg -eq "1" ]; then
	#			dep_dir="${build_dir_arg}/ws_${dependency_arg}/devel"
	#		else
	#			dep_dir="${build_dir_arg}/ws_${dependency_arg}/install"
	#		fi 
	#	fi
	#fi

	ws_dir="${build_dir_arg}/ws_${name_arg}"
	install_arg=""
	if [ ! -z $install_dir_arg ]; then
		install_arg="-i ${install_dir_arg}/ws_${name_arg}"
	elif [ $devel_space_only_arg -eq "1" ]; then
		install_arg=""
	else
		install_arg="-i ${build_dir_arg}/ws_${name_arg}/install"
	fi

	echo "Calling script: $setup_script $dep_dir $script_dir_arg $ws_dir $build_type_arg $install_arg $additional_options -- $@"
	bash $setup_script $dep_dir $script_dir_arg $ws_dir $build_type_arg $install_arg $additional_options -- "$@"
	if [ $? -ne 0 ]; then
		printError "The command finished with error. Terminating the setup script."
		exit 2
	fi
}

### Argument parsing, defaults:
# Installation directory (if separate from build)
install_dir=""
# Build type
build_type="RelWithDebInfo"
# Build directory (or fakeroot directory)
build_dir="build"
# Whether to use fakeroot
use_fakechroot=0
# Whether to build ws_gazebo
build_gazebo=0
# Whether to build ws_tiago
build_tiago=0
# Whether to build ws_orocos
build_orocos=0
# Whether to build ws_fabric
build_fabric=0
# Whether to build ws_velma
build_velma=0
# Whether to build ws_velma_hw
build_velma_hw=0
# Whether to build ws_elektron
build_elektron=0
# Build configuration passed to fakeroot
build_configuration=""

# DO NOT USE DEFAULT ARGS!!!!11
#if [ $# -eq 0 ]; then
#	echo "This will build and install the complete RCPRG robot software stack with default build options."
#	echo "Use '$0 --help' to see the available options and their defualt values."
#	read -r -p "Continue [Y/n]?" response
#	# tolower
#	response=${response,,}
#	if [[ $response =~ ^(yes|y| ) ]] || [ -z $response ]; then
#		echo "Starting the build!"
#		build_configuration=" -g -e -o -f -v"
#		build_elektron=1
#		build_gazebo=1
#		build_orocos=1
#		build_fabric=1
#		build_velma=1
#	else
#		exit 0
#	fi
#fi

while [[ $# -gt 0 ]]; do
	key="$1"

	case $key in
		-h|--help)
			usage
			exit 0
		;;
		-i|--install)
			install_dir="$2"
			shift 2
			if [ -z "$install_dir" ]; then
				printError "ERROR: wrong argument: install_dir"
				usage
				exit 1
			fi
		;;
		-b|--build-type)
			build_type="$2"
			shift 2
		;;
		-d|--build-dir)
			build_dir="$2"
			shift 2
		;;
		-F|--fakechroot)
			use_fakechroot=1
			shift
		;;
		-g|--gazebo)
			build_configuration+=" -g"
			build_gazebo=1
			shift
		;;
		-t|--tiago)
			build_configuration+=" -t"
			build_tiago=1
			shift
		;;
		-e|--elektron)
			build_configuration+=" -e"
			build_elektron=1
			shift
		;;
		-o|--orocos)
			build_configuration+=" -o"
			build_orocos=1
			shift
		;;
		-f|--fabric)
			build_configuration+=" -f"
			build_fabric=1
			shift
		;;
		-v|--velma)
			build_configuration+=" -v"
			build_velma=1
			shift
		;;
		-w|--velma-hw)
			build_configuration+=" -w"
			build_velma_hw=1
			shift
        ;;
        -x|--extend)
            dependency_dir="$2"
            shift 2
		;;
		--)
			#
			break
		;;
		*)
			printError "ERROR: wrong argument: $1"
			usage
			exit 1
		;;
	esac
done
shift

if [ -z "$dependency_dir" ]; then
	printError "Extension of workspace is not provided, please specify valid -x arg."
	usage
	exit 0
fi

script_dir=`pwd`
echo "script_dir: ${script_dir}"

# The script must be executed in RCPRG_rosinstall folder
if [ ! -d "$script_dir/workspace_defs" ]; then
	echo "ERROR: This script must be executed in RCPRG_rosinstall folder"
	exit 1
fi

### ROS check
if [ "$ROS_DISTRO" != "melodic" ]; then
	printError "ERROR: ROS melodic setup.bash have to be sourced!"
	exit 1
fi

### If no workspaces are selected - build everything
if [ $build_gazebo -eq 0 ] && [ $build_elektron -eq 0 ] && [ $build_orocos -eq 0 ] && [ $build_fabric -eq 0 ] && [ $build_velma -eq 0 ]&& [ $build_tiago -eq 0 ]; then
	build_configuration=" -g -e -o -f -v"
	build_gazebo=1
	build_elektron=1
	build_tiago=1
	build_orocos=1
	build_fabric=1
	build_velma=1
fi

# It is okay not to install Gazebo
### Check if required workspaces are installed in the /opt directory
#if [[ ! -d "/opt/ws_gazebo" ]] && [ $build_gazebo -eq 0 ]; then
#	# Gazebo is required for everything else
#	printError "Gazebo is not in the /opt directory, please install it or add <-g> flag to the script."
#	exit 1
#fi
if [[ ! -d "/opt/ws_gazebo" ]] && [ $build_gazebo -eq 0 ] && [[ $build_tiago -eq 1 ]] ; then
	# Orocos is required for Fabric and Velma
	printError "Gazebo is not in the /opt directory, please add <-g> flag to the script."
	exit 1
fi
if [[ ! -d "/opt/ws_orocos" ]] && [ $build_orocos -eq 0 ] && [[ $build_fabric -eq 1 || $build_velma -eq 1 ]] ; then
	# Orocos is required for Fabric and Velma
	printError "Orocos is not in the /opt directory, please install it or add <-o> flag to the script."
	exit 1
fi
if [[ ! -d "/opt/ws_fabric" ]] && [ $build_fabric -eq 0 ] && [ $build_velma -eq 1 ] ; then
	# Fabric is required for Velma only
	printError "Fabric is not in the /opt directory, please install it or add <-f> flag to the script."
	exit 1
fi
#if [[ ! -d "/opt/ws_velma_os" ]] && [ $build_velma_hw -eq 1 ] ; then
#	# VelmaOS is required for Velma HW
#	printError "VelmaOS is not in the /opt directory, please install it or add <-w> flag to the script."
#	exit 1
#fi

### Check build type
if [ "$build_type" != "Debug" ] && [ "$build_type" != "RelWithDebInfo" ] && [ "$build_type" != "Release" ]; then
	printError "ERROR: wrong argument: build_type=$build_type"
	usage
	exit 1
fi

### Dependencies
bash scripts/check_deps.sh workspace_defs/main_dependencies
if [ $build_tiago -eq 1 ]; then
		bash scripts/check_deps.sh workspace_defs/tiago_dependencies
fi

error=$?
if [ ! "$error" == "0" ]; then
	printError "error in dependencies: $error"
	exit 1
fi

### Fakeroot
if [ $use_fakechroot -eq 1 ]; then
	### install fakechroot if not present
	if [ -x "$(fakechroot -v)" ]; then
		echo "WARNING: fakechroot not installed, attempting install now"
		sudo apt install fakechroot
		if [ ! "$?" == "0" ]; then
			printError "error installing fakechroot"
			exit 1
		fi
	fi

	### Prepare the jail
	## create directories
	mkdir -p $build_dir
	if [ "$(ls -A $build_dir)" ]; then
		echo "WARNING: $build_dir is not empty, in case of errors try clean build first"
	fi
	mkdir -p $build_dir/usr
	mkdir -p $build_dir/opt

	## copy setup scripts etc.
	cp -a scripts $build_dir/
	cp -a workspace_defs $build_dir/
	cp -a setup.sh $build_dir/

	if [ -f "friComm.h" ]; then
		cp -a friComm.h $build_dir/
	fi

	## link in /opt/ros (if not linked already)
	if [[ ! -d $build_dir/opt/ros ]]; then
		ln -s /opt/ros $build_dir/opt/ros
	fi

	## link in workspaces that will be not compiled during this setup
	if [ $build_gazebo -eq 0 ]; then
		ln -s /opt/ws_gazebo $build_dir/opt/ws_gazebo
	fi
	if [ $build_velma -eq 1 ]; then	
		if [ $build_orocos -eq 0 ]; then
			ln -s /opt/ws_orocos $build_dir/opt/ws_orocos
		fi
		if [ $build_fabric -eq 0 ]; then
			ln -s /opt/ws_fabric $build_dir/opt/ws_fabric
		fi
	fi
	### Enter jail
	cd $build_dir

	### Execute build in jail
	# prepare install directory argument (so as not to pass "-i --")
	install_dir_arg=""
	if [ ! -z "$install_dir" ]; then
		install_dir_arg="-i $install_dir"
	fi
	# perform fakechroot and execute this script again, in jail
    echo "Executing:"
    echo "fakechroot -e stero -c $script_dir/fakechroot fakeroot /usr/sbin/chroot . ./setup.sh -x $dependency_dir $build_configuration -b $build_type -d $build_dir $install_dir_arg -- $@"
	fakechroot -e stero -c $script_dir/fakechroot fakeroot /usr/sbin/chroot . ./setup.sh -x $dependency_dir $build_configuration -b $build_type -d $build_dir $install_dir_arg -- "$@"
	exit 0
fi

### Paths
# Get absolute path for script root, build and install directories
script_dir=`pwd`

mkdir -p "$build_dir"
cd "$build_dir"
build_dir=`pwd`

if [ ! -z "$install_dir" ]; then
	mkdir -p "$install_dir"
	cd "$install_dir"
	install_dir=`pwd`
	devel_space_only="0"
else
	devel_space_only="1"
fi

### Build workspaces
# The variables have to be quoted to ensure they're passed to buildWorkspace function even if empty
if [ $build_gazebo -eq 1 ]; then
#	buildWorkspace "gazebo" "" "$build_type" "$script_dir" "$build_dir" "$install_dir" "$devel_space_only" "" "$@"
	buildWorkspace "gazebo" "$dependency_dir" "$build_type" "$script_dir" "$build_dir" "$install_dir" "$devel_space_only" "" "$@"
	if [ ! -z $install_dir ]; then
		dependency_dir="${install_dir}/ws_gazebo"
	else
		if [ $devel_space_only -eq "1" ]; then
			dependency_dir="${build_dir}/ws_gazebo/devel"
		else
			dependency_dir="${build_dir}/ws_gazebo/install"
		fi
    fi
fi
if [ $build_elektron -eq 1 ]; then
	buildWorkspace "elektron" "$dependency_dir" "$build_type" "$script_dir" "$build_dir" "$install_dir" "$devel_space_only" "" "$@"
fi
if [ $build_tiago -eq 1 ]; then
	buildWorkspace "tiago" "$dependency_dir" "$build_type" "$script_dir" "$build_dir" "$install_dir" "$devel_space_only" "" "$@"
	if [ ! -z $install_dir ]; then
		dependency_dir="${install_dir}/ws_tiago"
	else
		if [ $devel_space_only -eq "1" ]; then
			dependency_dir="${build_dir}/ws_tiago/devel"
		else
			dependency_dir="${build_dir}/ws_tiago/install"
		fi
    fi
fi
if [ $build_orocos -eq 1 ]; then
#	buildWorkspace "orocos" "gazebo" "$build_type" "$script_dir" "$build_dir" "$install_dir" "$devel_space_only" "" "$@"
	buildWorkspace "orocos" "$dependency_dir" "$build_type" "$script_dir" "$build_dir" "$install_dir" "$devel_space_only" "" "$@"
	if [ ! -z $install_dir ]; then
		dependency_dir="${install_dir}/ws_orocos"
	else
		if [ $devel_space_only -eq "1" ]; then
			dependency_dir="${build_dir}/ws_orocos/devel"
		else
			dependency_dir="${build_dir}/ws_orocos/install"
		fi
    fi
fi
if [ $build_fabric -eq 1 ]; then
	buildWorkspace "fabric" "$dependency_dir" "$build_type" "$script_dir" "$build_dir" "$install_dir" "$devel_space_only" "" "$@"

	if [ ! -z $install_dir ]; then
		dependency_dir="${install_dir}/ws_fabric"
	else
		if [ $devel_space_only -eq "1" ]; then
			dependency_dir="${build_dir}/ws_fabric/devel"
		else
			dependency_dir="${build_dir}/ws_fabric/install"
		fi
    fi
fi
if [ $build_velma -eq 1 ]; then
	#if [ $build_gazebo -eq 1 ]; then
	#	additional_options="-g"
	#fi
	if [ $build_velma_hw -eq 1 ]; then
		additional_options="-w"
    else
		additional_options="-g"
	fi
	buildWorkspace "velma_os" "$dependency_dir" "$build_type" "$script_dir" "$build_dir" "$install_dir" "$devel_space_only" "$additional_options" "$@"
fi
#if [ $build_velma_hw -eq 1 ]; then
#	buildWorkspace "velma_hw" "velma_os" "$build_type" "$script_dir" "$build_dir" "$install_dir" "$devel_space_only" "$@"
#fi
