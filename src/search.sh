#!/usr/bin/env bash

source config
source workflowUtils.sh
source pycharmUtils.sh

QUERY=$1

# Check if Pycharm APP is already installed
if [ ! -r "$APP_PATH" ]; then
	noPycharmApp
	exit
fi

# Check pycharm app version
MAJOR_VERSION=$(getVersionInfo | awk '{print $1}')
if [ "$MAJOR_VERSION" -lt 2019 ]; then
  unSupportVersion
	exit
fi

if [ "$MAJOR_VERSION" == 2019 ] || [ "$MAJOR_VERSION" == 2020 ]; then
  if [ ! -r "$LAUNCHER_COMMAND_FOR_2019_AND_2020" ]; then
    noFoundCommandLine
    exit
  fi
fi

RECENT_PROJECTS=$(getRecentProjects "$QUERY")
if [ "${RECENT_PROJECTS}" ]; then
  # 格式化result，生成Alfred需要的JSON数据
  ALFRED_RESULT=$(formatResult "${RECENT_PROJECTS}")
  echo "$ALFRED_RESULT"
  exit
else
  noProjectMatched
  exit
fi