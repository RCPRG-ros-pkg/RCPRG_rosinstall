#!/usr/bin/env bash

function usage {
	echo "usage: $0 <extend_directory> <script_dir> <build_directory> <build_type> [options] [-- catkin_build_opts]"
	echo "<build_type> can be one of (Debug|RelWithDebInfo|Release)"
	echo "Options:"
	echo "  -i [ --install ] arg   Install to directory"
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
wstool merge ${script_dir}/workspace_defs/gazebo_dart.rosinstall
if [ $? -ne 0 ]; then
	printError "The command wstool merge terminated  with error. Terminating the setup script."
	exit 2
fi
wstool update
if [ $? -ne 0 ]; then
	printError "The command wstool update terminated with error. Terminating the setup script."
	exit 3
fi

### Bugfixes/workarounds
## Gazebo download
#wget -c https://github.com/osrf/gazebo/archive/gazebo9.zip -O src/gazebo/gazebo9.zip
#unzip src/gazebo/gazebo9.zip -d src/gazebo
#mv src/gazebo/gazebo-gazebo9 src/gazebo/gazebo
## Gazebo package.xml
# Download package.xml for Gazebo
wget -c https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_gazebo.xml -O src/gazebo/gazebo/package.xml
if [ $? -ne 0 ]; then
	printError "Could not download package.xml for Gazebo."
	exit 4
fi
# Fix it for new dartsim identifier ("dartsim" instead of "dart")
sed -i -e 's/>dart</>dartsim</g' src/gazebo/gazebo/package.xml
## Gazebo dependencies
# fix gazebo compile depenedencies
sed -i -e 's/<build_export_depend>libgazebo9-dev<\/build_export_depend>/ /g' src/gazebo/gazebo_ros_pkgs/gazebo_dev/package.xml
sed -i -e 's/<exec_depend>gazebo9<\/exec_depend>/<depend>gazebo<\/depend>/g' src/gazebo/gazebo_ros_pkgs/gazebo_dev/package.xml

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
if [ $? -ne 0 ]; then
	printError "Command catkin config failed."
	exit 5
fi

### Build
catkin build $catkin_build_opts
if [ $? -ne 0 ]; then
	printError "Command catkin build failed."
	exit 6
fi

