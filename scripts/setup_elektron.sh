#!/usr/bin/env bash

function usage {
	echo "usage: $0 <extend_directory> <script_dir> <build_directory> <build_type> [options] [-- catkin_build_opts]"
	echo "<build_type> can be one of (Debug|RelWithDebInfo|Release)"
	echo "Options:"
	echo "  -i [ --install ] arg   Install to directory"
	echo "catkin_build_opts are passed to 'catkin build' command"
}

function usage {
	echo "usage: $0 extend_directory build_directory build_type [-i install_directory]"
}

function printError {
	RED='\033[0;31m'
	NC='\033[0m'
	echo -e "${RED}$1${NC}"
}

install_dir=""
catkin_build_opts=""

### Arguments
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
wstool merge ${script_dir}/workspace_defs/common_elektron.rosinstall
wstool update

### Bugfixes/workarounds
# Unregister submodules for hw camera support and for Rapp
cd $build_dir/src/elektron
git submodule deinit elektron_apps/elektron-rapps netusb_camera_driver rapp-api-elektron
cd $build_dir
# Disable all Yujin OCS packages but yocs_cmd_vel_mux
touch src/yujin_ocs/{yocs_ar_marker_tracking,yocs_ar_pair_approach,yocs_ar_pair_tracking,yocs_controllers,yocs_diff_drive_pose_controller,yocs_joyop,yocs_keyop,yocs_localization_manager,yocs_math_toolkit,yocs_navi_toolkit,yocs_navigator,yocs_rapps,yocs_safety_controller,yocs_velocity_smoother,yocs_virtual_sensor,yocs_waypoint_provider,yocs_waypoints_navi,yujin_ocs}/CATKIN_IGNORE
# Disable all scan_tools packages but laser_scan_matcher
touch src/scan_tools/{laser_ortho_projector,laser_scan_sparsifier,laser_scan_splitter,ncd_parser,polar_scan_matcher,scan_to_cloud_converter,scan_tools}/CATKIN_IGNORE

### Configure
CMAKE_ARGS="\
 -DCMAKE_BUILD_TYPE=${build_type}\
 -DCATKIN_ENABLE_TESTING=OFF\
"

catkin config $install_opt --extend $extend_dir --cmake-args $CMAKE_ARGS

### Build
# catkin build $catkin_build_opts
