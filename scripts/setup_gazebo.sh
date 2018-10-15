#!/usr/bin/env bash

function usage {
	echo "usage: $0 <extend_directory> <build_directory> <build_type> [options]"
	echo "<build_type> can be one of (Debug|RelWithDebInfo|Release)"
	echo "Options:"
	echo "  -i [ --install ] arg   Install to directory"
	echo "  -j arg                 Use 'arg' CPU cores"
}

function printError {
	RED='\033[0;31m'
	NC='\033[0m' # No Color
	echo -e "${RED}$1${NC}"
}

install_opt=""
num_cores=""

# parse command line arguments
POSITIONAL=()
while [[ $# -gt 0 ]]; do
	key="$1"
	case $key in
		-i | --install )
			install_opt="$2"
			shift 2 # past argument
			#shift # past value
			if [ -z "$install_opt" ]; then
				printError "ERROR: wrong argument: install_opt"
				usage
				exit 1
			else
				install_opt="-i $install_opt --install"
			fi
		;;
		-j )
			num_cores="$2"
			shift 2 # past argument
			#shift # past value
		;;
		*)
			POSITIONAL+=("$1") # save it in an array for later
			shift # past argument
		;;
	esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ -z "$1" ]; then
	printError "Wrong argument 1: $1"
	usage
	exit 1
fi

if [ -z "$2" ]; then
	printError "Wrong argument 2: $2"
	usage
	exit 1
fi

if [ -z "$3" ]; then
	printError "Wrong argument 3: $3"
	usage
	exit 1
fi

extend_dir="$1"
build_dir="$2"
build_type="$3"

### Prepare workspace
mkdir -p $build_dir/src
cd $build_dir
if [ ! -e ".rosinstall" ]; then
	wstool init
fi
wstool merge ${script_dir}/workspace_defs/gazebo_dart.rosinstall
wstool update

### Download and prepare Gazebo
# Download Gazebo package - workaround for HTTP error 400 when cloning huge mercurial repos
# Issue: https://bitbucket.org/site/master/issues/8263/http-400-bad-request-error-when-pulling
wget -c https://bitbucket.org/osrf/gazebo/get/gazebo9.tar.bz2 -O src/gazebo/gazebo9.tar.bz2
# tar options: eXtract, Bzip2, Keep old files, Filename; output dir
tar -xBkf src/gazebo/gazebo9.tar.bz2 -C src/gazebo
# Rename extracted directory - it'll look like "osrf-gazebo-37909779f2fd"
mv src/gazebo/osrf-gazebo-* src/gazebo/gazebo
# Download package.xml for Gazebo
wget -c https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_gazebo.xml -O src/gazebo/gazebo/package.xml
# Fix it for new dartsim identifier ("dartsim" instead of "dart")
sed -i -e 's/>dart</>dartsim</g' src/gazebo/gazebo/package.xml

#fix gazebo compile depenedencies
sed -i -e 's/<build_export_depend>libgazebo9-dev<\/build_export_depend>/ /g' src/gazebo/gazebo_ros_pkgs/gazebo_dev/package.xml
# sed -i -e 's/<build_export_depend>libgazebo9-dev<\/build_export_depend>/<build_depend>gazebo<\/build_depend>/g' src/gazebo/gazebo_ros_pkgs/gazebo_dev/package.xml
sed -i -e 's/<exec_depend>gazebo9<\/exec_depend>/<depend>gazebo<\/depend>/g' src/gazebo/gazebo_ros_pkgs/gazebo_dev/package.xml

echo "seds"

### Config
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

if [ ! -z "$num_cores" ]; then
	num_cores_str=" -j $num_cores"
else
	num_cores_str=""
fi

### Build
# catkin build --no-status
catkin build "$num_cores_str"
