#!/bin/bash
set -ev

# Configuration.
export CATKIN_WS=~/catkin_ws
export CATKIN_WS_SRC=${CATKIN_WS}/src
export DEBIAN_FRONTEND=noninteractive

apt update -qq
apt install -qq -y lsb-release wget curl build-essential

if [ "$IGNITION_VERSION" == "blueprint" ]; then
  IGN_DEPS="libignition-msgs4-dev libignition-transport7-dev libignition-gazebo2-dev"
elif [ "$IGNITION_VERSION" == "citadel" ]; then
  IGN_DEPS="libignition-msgs5-dev libignition-transport8-dev libignition-gazebo3-dev"
elif [ "$IGNITION_VERSION" == "dome" ]; then
  IGN_DEPS="libignition-msgs6-dev libignition-transport9-dev libignition-gazebo4-dev"
else
  exit 1
fi

# Dependencies.
echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list
wget https://packages.osrfoundation.org/gazebo.key -O - | apt-key add -
echo "deb http://packages.ros.org/ros/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/ros-latest.list
curl -sSL 'http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xC1CF6E31E6BADE8868B172B4F42ED6FBAB17C654' | apt-key add -
apt-get update -qq
apt-get install -qq -y $IGN_DEPS \
                       python-catkin-tools \
                       python-rosdep

rosdep init
rosdep update
rosdep install --from-paths ./ -i -y --rosdistro $ROS_DISTRO \
  --skip-keys=ignition-gazebo2 \
  --skip-keys=ignition-gazebo3 \
  --skip-keys=ignition-gazebo4 \
  --skip-keys=ignition-msgs4 \
  --skip-keys=ignition-msgs5 \
  --skip-keys=ignition-msgs6 \
  --skip-keys=ignition-rendering2 \
  --skip-keys=ignition-rendering3 \
  --skip-keys=ignition-sensors2 \
  --skip-keys=ignition-sensors3 \
  --skip-keys=ignition-transport7 \
  --skip-keys=ignition-transport8 \
  --skip-keys=ignition-transport9 \

# Build.
source /opt/ros/$ROS_DISTRO/setup.bash
mkdir -p $CATKIN_WS_SRC
ln -s $GITHUB_WORKSPACE $CATKIN_WS_SRC
cd $CATKIN_WS
catkin init
catkin config --install
catkin build --limit-status-rate 0.1 --no-notify -DCMAKE_BUILD_TYPE=Release
catkin build --limit-status-rate 0.1 --no-notify --make-args tests

# Tests.
catkin run_tests
