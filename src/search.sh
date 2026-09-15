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

# 调用函数
expanded_path=$(is_path "$QUERY")
ret=$?

if [ $ret -eq 0 ]; then
    # 输入是路径（~/xxx 或者 /xxx），expanded_path 是完整绝对路径
    if [[ -d "$expanded_path" ]]; then
        # 文件夹存在，直接返回Alfred item
        echo '{"items": [
        {
            "uid": "",
            "type": "",
            "title": "Your Search exists",
            "subtitle": "'"$QUERY"'",
            "arg": "",
            "autocomplete": "",
        }]}'
    else
        # 路径格式合法，但文件夹不存在
        echo '{"items": [
        {
            "uid": "",
            "type": "",
            "title": "Your Search does not exist",
            "subtitle": "try another search",
            "arg": "",
            "icon": {
                "path": "./warning.png"
            },
            "autocomplete": "",
        }]}'
    fi
else
    # 普通关键词，执行mdfind搜索
    # Search Recent Projects
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
fi

