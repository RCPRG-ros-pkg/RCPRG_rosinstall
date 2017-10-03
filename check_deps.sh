#!/bin/bash

export LANG=en_US.UTF-8

function printError {
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo -e "${RED}$1${NC}"
}

if [ $# -ne 2 ]; then
    echo "wrong number of arguments: $#"
    exit 1
fi

file_deps="$1"
file_conflicts="$2"

if [ ! -f "$file_deps" ]; then
    exit 2
fi

if [ ! -f "$file_conflicts" ]; then
    exit 3
fi

installed=()
while read -r line || [[ -n "$line" ]]; do
    installed=("${installed[@]}" "$line")
done < "$file_deps"

uninstalled=()
while read -r line || [[ -n "$line" ]]; do
    uninstalled=("${uninstalled[@]}" "$line")
done < "$file_conflicts"

error=false

# check the list of packages that should be installed
for item in ${installed[*]}
do
    aaa=`dpkg --get-selections | grep $item`
    if [ -z "$aaa" ]; then
        printError "ERROR: package $item is not installed. Please INSTALL it."
        error=true
    else
        arr=($aaa)
        name=${arr[0]}
        status=${arr[1]}
        if [ "$status" != "install" ]; then
            printError "ERROR: package $name is not installed. Please INSTALL it."
            error=true
        else
            echo "OK: package $name is installed"
        fi
    fi
done

# check the list of packages that should be uninstalled
for item in ${uninstalled[*]}
do
    aaa=`dpkg --get-selections | grep $item`
    if [ -z "$aaa" ]; then
        echo "OK: the package $item is not installed."
    else
        arr=($aaa)
        name=${arr[0]}
        status=${arr[1]}
        if [ "$status" != "install" ]; then
            echo "OK: the package $name is not installed."
        else
            printError "ERROR: package $name is installed. Please UNINSTALL it."
            error=true
        fi
    fi
done

if [ "$error" = true ]; then
    echo "Please install/uninstall the listed packages"
    echo "To install libccd please see http://askubuntu.com/questions/664101/dependency-in-ppa"
    exit 4
fi

exit 0

