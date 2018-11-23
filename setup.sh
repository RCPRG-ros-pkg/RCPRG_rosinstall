#!/usr/bin/env bash

function usage {
	echo "usage: $0 [options] [-- catkin_build_opts]"
	echo "Options:"
	echo "  -h [ --help ]            Display this message and exit"
	echo "  -d [ --build-dir ] arg   Build directory, defaults to 'build'"
	echo "  -b [ --build-type ] arg  Build type, can be one of (Debug|RelWithDebInfo|Release), defaults to 'RelWithDebInfo'"
	echo "  -i [ --install ] arg     Install to directory"
	echo "  -F [ --fakechroot ]      build in fake root directory"
	echo "  -e [ --elektron ]        build elektron workspace"
	echo "  -g [ --gazebo ]          build gazebo workspace"
	echo "  -o [ --orocos ]          build orocos workspace"
	echo "  -f [ --fabric ]          build fabric workspace"
	echo "  -v [ --velma ]           build velma workspace"
	echo "catkin_build_opts are passed to 'catkin build' command"
}

function printError {
	RED='\033[0;31m'
	NC='\033[0m'
	echo -e "${RED}$1${NC}"
}

function buildWorkspace {
	name=$1
	dependency=$2
	build_type=$3
	script_dir=$4
	build_dir=$5
	install_dir=$6
	shift 6

	setup_script="${script_dir}/scripts/setup_${name}.sh"
	dep_dir="/opt/ros/melodic"
	if [ ! -z $dependency ]; then
		if [ ! -z $install_dir ]; then
			dep_dir="${install_dir}/ws_${dependency}"
		else
			dep_dir="${build_dir}/ws_${dependency}/install"
		fi
	fi
	ws_dir="${build_dir}/ws_${name}"
	install_arg=""
	if [ ! -z $install_dir ]; then
		install_arg="-i ${install_dir}/ws_${name}"
	else
		install_arg="-i ${build_dir}/ws_${name}/install"
	fi

	echo "Calling script: $setup_script $dep_dir $script_dir $ws_dir $build_type $install_arg -- $@"
	bash $setup_script $dep_dir $script_dir $ws_dir $build_type $install_arg -- "$@"
	if [ $? -ne 0 ]; then
		printError "The command finished with error. Terminating the setup script."
		exit 2
	fi
}

### ROS check
if [ "$ROS_DISTRO" != "melodic" ]; then
	printError "ERROR: ROS melodic setup.bash have to be sourced!"
	exit 1
fi

if [ $# -eq 0 ]; then
	echo "This will build and install the complete RCPRG robot software stack with default build options."
	echo "Use '$0 --help' to see the available options and their defualt values."
	read -r -p "Continue [Y/n]?" response
	# tolower
	response=${response,,}
	if [[ $response =~ ^(yes|y| ) ]] || [ -z $response ]; then
		echo "Starting the build!"
	else
		exit 0
	fi
fi

### Argument parsing
# Defaults:
install_dir=""
build_type="RelWithDebInfo"
build_dir="build"
use_fakechroot=0
build_elektron=0
build_gazebo=0
build_orocos=0
build_fabric=0
build_velma=0
build_configuration=""
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
			build_configuration+=" -g "
                        build_gazebo=1
                        shift
                ;;
                -e|--elektron)
                        build_configuration+=" -e "
                        build_elektron=1
			shift
                ;;
                -o|--orocos)
			build_configuration+=" -o "
                        build_orocos=1
                        shift
                ;;
                -f|--fabric)
			build_configuration+=" -f "
                        build_fabric=1
                        shift
                ;;
                -v|--velma)
			build_configuration+=" -v "
                        build_velma=1
                        shift
                ;;

		--)
			shift
			break
		;;
		*)
			printError "ERROR: wrong argument: $1"
			usage
			exit 1
		;;
	esac
done

### Check if required workspaces are installed in the /opt directory
if [[ ! -d "/opt/ws_gazebo" ]] && [ $build_gazebo -eq 0 ] && [ $build_elektron -eq 1 ] ; then
	printError "Gazebo is not in the /opt directory, please install it or add <-g> flag to the script."
	exit 1
fi
if [[ ! -d "/opt/ws_gazebo" ]] && [ $build_gazebo -eq 0 ] && [ $build_orocos -eq 1 ] ; then
        printError "Gazebo is not in the /opt directory, please install it or add <-g> flag to the script."
        exit 1
fi
if [[ ! -d "/opt/ws_orocos" ]] && [ $build_orocos -eq 0 ] && [ $build_fabric -eq 1 ] ; then
        printError "Orocos is not in the /opt directory, please install it or add <-o> flag to the script."
        exit 1
fi
if [[ ! -d "/opt/ws_fabric" ]] && [ $build_fabric -eq 0 ] && [ $build_velma -eq 1 ] ; then
        printError "Fabric is not in the /opt directory, please install it or add <-f> flag to the script."
        exit 1
fi

### Check build type
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
script_dir=`pwd`
### Fakeroot
#export FAKECHROOT_CMD_ORIG=
if [ $use_fakechroot -eq 1 ]; then
	# create jail
	mkdir -p $build_dir
	if [ "$(ls -A $build_dir)" ]; then
		echo "WARNING: $build_dir is not empty"
	fi

	# copy setup scripts etc.
	cp -a scripts $build_dir/
	cp -a workspace_defs $build_dir/
	cp -a setup.sh $build_dir/

	mkdir -p $build_dir/usr

	# link /opt/ros
	mkdir -p $build_dir/opt
	ln -s /opt/ros $build_dir/opt/ros
	
	echo $build_dir/opt/ws_gazebo

	# link workspaces that will be not compiled during this setup
        if [ $build_gazebo -eq 0 ] && [ $build_elektron -eq 1 ]; then
                ln -s /opt/ws_gazebo $build_dir/opt/ws_gazebo
        fi
        if [ $build_orocos -eq 0 ] && [ $build_fabric -eq 1 ]; then
                ln -s /opt/ws_orocos $build_dir/opt/ws_orocos
        fi
        if [ $build_orocos -eq 0 ] && [ $build_velma -eq 1 ]; then
                ln -s /opt/ws_orocos $build_dir/opt/ws_orocos
        fi
        if [ $build_fabric -eq 0 ] && [ $build_velma -eq 1 ]; then
                ln -s /opt/ws_fabric $build_dir/opt/ws_fabric
        fi

	# move to jail
	cd $build_dir

	# create build configuration
	# perform fakechroot and execute this script again, in jail
	fakechroot -e stero -c $script_dir/fakechroot fakeroot /usr/sbin/chroot . ./setup.sh $build_configuration -b $build_type -d $build_dir -i $install_dir "$@"
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
fi


### Build workspaces
# The variables have to be quoted to ensure they're passed to buildWorkspace function even if empty

if [ $build_gazebo -eq 1 ]; then
	buildWorkspace "gazebo" "" "$build_type" "$script_dir" "$build_dir" "$install_dir" "$@"
fi

if [ $build_elektron -eq 1 ]; then
        buildWorkspace "elektron" "gazebo" "$build_type" "$script_dir" "$build_dir" "$install_dir" "$@"
fi

if [ $build_orocos -eq 1 ]; then
	buildWorkspace "orocos" "gazebo" "$build_type" "$script_dir" "$build_dir" "$install_dir" "$@"
fi

if [ $build_fabric -eq 1 ]; then
	buildWorkspace "fabric" "orocos" "$build_type" "$script_dir" "$build_dir" "$install_dir" "$@"
fi

if [ $build_velma -eq 1 ]; then
	buildWorkspace "velma_os" "fabric" "$build_type" "$script_dir" "$build_dir" "$install_dir" "$@"
fi
