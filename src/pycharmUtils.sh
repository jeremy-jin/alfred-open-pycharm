#!/usr/bin/env bash

source ./config

function getVersionInfo() {
  APP_INFO_PATH=${APP_PATH}'/Contents/Info.plist'
  VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_INFO_PATH")
  read -r MAJOR_VERSION SUB_VERSION PHASE_VERSION <<< "${VERSION//./ }"
  echo "$MAJOR_VERSION" "$SUB_VERSION" "$PHASE_VERSION"
}

function getRecentProjectsDir() {
   read -r MAJOR_VERSION SUB_VERSION PHASE_VERSION <<< "$(getVersionInfo)"
   echo "${APP_SUPPORT_DIR}${MAJOR_VERSION}.${SUB_VERSION}"
}

function getRecentProjects() {
  QUERY=$1
  MAJOR_VERSION=$(getVersionInfo | awk '{print $1}')
  # 根据不同版本，获取信息位置不同
  if [ "$MAJOR_VERSION" == "2019" ]; then
    RECENT_PROJECTS_XML='/options/recentProjectDirectories.xml'
    RECENT_XPATH=".//component[@name='RecentDirectoryProjectsManager']/option[@name='recentPaths']/list/option/@value"

  elif [ "$MAJOR_VERSION" -ge "2020" ]; then
    RECENT_PROJECTS_XML='/options/recentProjects.xml'
    RECENT_XPATH=".//component[@name='RecentProjectsManager']/option[@name='additionalInfo']/map/entry/@key"

  fi

  if [ "$RECENT_PROJECTS_XML" ]; then
    RECENT_PROJECTS_DIR=$(getRecentProjectsDir)
    RECENT_PROJECTS=$(xmllint --xpath "${RECENT_XPATH}" "${RECENT_PROJECTS_DIR}${RECENT_PROJECTS_XML}")
    RESULTS=()
    for project in $RECENT_PROJECTS:
    do
      project_path=$(echo "$project" | awk -v HOME="${HOME}" -F '"' '{sub(/\$USER_HOME\$/, HOME); print $2}')
      if [ "$QUERY" ]; then
        project_name=$(echo "$project_path" | awk -F '/' '{print $NF}')
        match_result=$(echo "$project_name" | grep "${QUERY}")
        if [ "$match_result" ]; then
          RESULTS+=("$project_path")
        fi
      else
        # 如果没有输入过滤字符串，直接添加结果列表中
        RESULTS+=("$project_path")
      fi
    done
    echo "${RESULTS[@]}"
  fi
}



