#!/usr/bin/env bash

source config
source pycharmUtils.sh

# Check pycharm app version
MAJOR_VERSION=$(getVersionInfo | awk '{print $1}')
if [ "$MAJOR_VERSION" == 2019 ] || [ "$MAJOR_VERSION" == 2020 ]; then
  eval "$LAUNCHER_COMMAND_FOR_2019_AND_2020 $1"
else
  eval "$LAUNCHER_COMMAND_FOR_2021_AND_AFTER --args $1"
fi