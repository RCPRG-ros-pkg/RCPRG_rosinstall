#!/usr/bin/env bash

function printError {
	RED='\033[0;31m'
	NC='\033[0m' # No Color
	echo -e "${RED}$1${NC}"
}

function printWarning {
	YELLOW='\033[33m'
	NC='\033[0m' # No Color
	echo -e "${YELLOW}$1${NC}"
}

### Parse args
if [ $# -ne 3 ] && [ $# -ne 2 ] && [ $# -ne 1 ]; then
	echo "wrong number of arguments: $#"
	exit 1
fi

install_all_deps=""

while [[ $# -gt 0 ]]; do
	key="$1"

	case $key in
		-i|install)
			file_deps="$2"
			shift 2
		;;
		-r|--remove)
			file_conflicts="$2"
			shift 2
		;;
		-y)
			install_all_deps="-y"
			shift
		;;
		*)
			printError "ERROR: wrong argument: $1"
			usage
			exit 1
		;;
	esac
done
shift

if [ ! -f "$file_deps" ]; then
	exit 2
fi

IFS=$'\n' read -d '' -r -a installed < $file_deps


error=false

# Get list of installed packages
package_list=`dpkg --get-selections`

# check the list of packages that should be installed
to_install=""
for item in ${installed[*]}; do
	echo "$package_list" | grep -q "$item"
	if [ $? -ne 0 ]; then
		echo $item
		to_install="$item $to_install"
	fi
done

if [ "$to_install" ]; then
	printWarning "Need to install $to_install"
	sudo apt install "$install_all_deps" $to_install
	if [ $? -ne 0 ]; then
		printError "ERROR: packages    $to_install is not installed. Please INSTALL it."
		error=true;
	fi
fi

if [ -f "$file_conflicts" ]; then

	uninstalled=()
	while read -r line || [[ -n "$line" ]]; do
		uninstalled=("${uninstalled[@]}" "$line")
	done < "$file_conflicts"

	# check the list of packages that should be uninstalled
	for item in ${uninstalled[*]}; do
		if [[ $package_list == .*$item.* ]]; then
			#if [ "$install_req" == "-i" ]; then
			printWarning "Need to remove "$item""
			sudo apt remove "$install_all_deps" "$item"
			#else
			#	printError "ERROR: package $name is installed. Please UNINSTALL it."
			#	error=true
			#fi
		fi
	done
fi

if [ "$error" = true ]; then
	exit 4
fi

exit 0

