#!/usr/bin/env bash

source ./workflow-utils.sh

QUERY=$1
LAUNCHER_DIR='/usr/local/bin/charm'

# 检查文件是否存在且可读
# 不存在或者不可读时，提示缺少文件，需要通过"jetbrains-alfred-workflow"创建文件
if [ ! -r $LAUNCHER_DIR ]; then
	noFoundCommandLine
	exit
fi

# 获取Pycharm的信息

# .e.g: ~/Library/Application Support/JetBrains/PyCharm2021.3
CONFIG_PATH=$(grep "CONFIG_PATH =" $LAUNCHER_DIR | awk -F "'" '{print $2}')
# .e.g: /Applications/PyCharm.app
RUN_PATH=$(grep "RUN_PATH =" $LAUNCHER_DIR | awk -F "'" '{print $2}')
# .e.g: /Applications/PyCharm.app/Contents/Info.plist
APP_INFO_PATH=${RUN_PATH}'/Contents/Info.plist'
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_INFO_PATH")
VERSION=(${VERSION//./ })
VERSION_YEAR=${VERSION[0]}
VERSION_MONTH=${VERSION[1]}

# 根据不同版本，获取信息位置不同
if [ "$VERSION_YEAR" == "2019" ]; then
	RECENT_PROJECTS_XML='/options/recentProjectDirectories.xml'
	RECENT_XPATH=".//component[@name='RecentDirectoryProjectsManager']/option[@name='recentPaths']/list/option/@value"

elif [ "$VERSION_YEAR" -ge "2020" ]; then
	RECENT_PROJECTS_XML='/options/recentProjects.xml'
	RECENT_XPATH=".//component[@name='RecentProjectsManager']/option[@name='additionalInfo']/map/entry/@key"

fi

# 不支持的版本，跳出
if [ ! $RECENT_PROJECTS_XML ]; then
	unSupportVersion
	exit
fi

# 获取最近打开的项目
recent_projects=$(xmllint --xpath "${RECENT_XPATH}" "${CONFIG_PATH}${RECENT_PROJECTS_XML}")
results=()

# 遍历过滤最近打开的项目，得到过滤后的项目地址Array
for project in $recent_projects
do
	project_path=$(echo "$project" | awk -v HOME="${HOME}" -F '"' '{sub(/\$USER_HOME\$/, HOME); print $2}')
	if [ "$QUERY" ]; then
		project_name=$(echo "$project_path" | awk -F '/' '{print $NF}')
		match_result=$(echo "$project_name" | grep "${QUERY}")
		if [ "$match_result" ]; then
			results+=("$project_path")
		fi
	else
		# 如果没有输入过滤字符串，直接添加结果列表中
		results+=("$project_path")
	fi
done

if [ ${results} ]; then
	# 格式化result，生成Alfred需要的JSON数据
	alfred_result=$(formatResult "${results[@]}")
	echo "$alfred_result"
	exit
else
	noProjectMatched
	exit
fi