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

install_req="$1"
if [ "$install_req" != "-i" ]; then
	file_deps="$1"
	file_conflicts="$2"
else
	file_deps="$2"
	file_conflicts="$3"
fi

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
	sudo apt install  $to_install
	if [ $? -ne 0 ]; then
		printError "ERROR: packages    $to_install is not installed. Please INSTALL it."
		error=true;
	fi
fi


# Remove packages passed as conflicting ones (make sure they're not in the system)
if [ $# -eq 3 ] || ([ $# -eq 2 ] &&  [ "$install_req" != "-i" ]); then
	if [ ! -f "$file_conflicts" ]; then
		exit 3
	fi

	uninstalled=()
	while read -r line || [[ -n "$line" ]]; do
		uninstalled=("${uninstalled[@]}" "$line")
	done < "$file_conflicts"

	# check the list of packages that should be uninstalled
	for item in ${uninstalled[*]}; do
		if [[ $package_list == .*$item.* ]]; then
			if [ "$install_req" == "-i" ]; then
				printWarning "Need to remove "$item""
				sudo apt remove "$item"
			else
				printError "ERROR: package $name is installed. Please UNINSTALL it."
				error=true
			fi
		fi
	done
fi

if [ "$error" = true ]; then
	exit 4
fi

exit 0

