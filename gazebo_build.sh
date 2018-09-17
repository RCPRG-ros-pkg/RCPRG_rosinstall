#!/bin/bash

#
sudo apt-add-repository ppa:dartsim
sudo apt update

sudo apt remove -y '.*gazebo.*'

BASE_DEPENDENCIES="\
  cppcheck\
  gnupg2\
  xsltproc\
"

GAZEBO_BASE_DEPENDENCIES="\
  freeglut3-dev\
  libboost-all-dev\
  libbullet-dev\
  libcurl4-openssl-dev\
  libdart6-all-dev\
  libfreeimage-dev\
  libgts-dev\
  libltdl-dev\
  libogre-1.9-dev\
  libprotobuf-dev\
  libprotoc-dev\
  libqwt-qt5-dev\
  libsimbody-dev\
  libtar-dev\
  libtbb-dev\
  libtinyxml-dev\
  libtinyxml2-dev\
  libxml2-dev\
  pkg-config\
  protobuf-compiler\
  qtbase5-dev\
"

sudo apt install -y $BASE_DEPENDENCIES
sudo apt install -y $GAZEBO_BASE_DEPENDENCIES

hg clone https://bitbucket.org/osrf/gazebo ~/gazebo-build
cd ~/gazebo-build
hg checkout gazebo9

sed -i -e 's/libogre-dev/libogre-1.9-dev/g' cmake/gazebo_cpack.cmake
sed -i -e 's/libqt4-dev/qtbase5-dev/g' cmake/gazebo_cpack.cmake

mkdir -p build
cd build
cmake ..
make -j8
cpack -G DEB
