#!/usr/bin/env zsh

# ========== 【配置区，自行修改】 ==========
MANIFEST_URL="https://raw.githubusercontent.com/jeremy-jin/alfred-open-pycharm/master/src/manifest.json"
CACHE_DIR="${alfred_workflow_cache}"
CACHE_DATE="${CACHE_DIR}/last_check_date.txt"
CACHE_IGNORE_VER="${CACHE_DIR}/ignored_version.txt"
TEMP_FILE_PREFIX="com.jeremy.alfred.open-pycharm"
# =========================================

# 版本比较函数：version_gt A B，A>B 返回0(true)
version_gt() {
  test "$(printf '%s\n' "$@" | sort -V | head -n1)" != "$1"
}

# 【核心更新检查函数】source安全版本，内部自带严格模式+自动恢复shell选项
check_workflow_update() {
    # 保存当前shell所有选项
    local OLD_OPTS
    OLD_OPTS=$(set +o)
    # 函数内开启严格模式，仅本函数内生效
    set -euo pipefail

    # 1. 创建缓存目录，失败直接返回
    mkdir -p "${CACHE_DIR}" || {
      echo "[update] failed to create cache dir" >&2
      eval "$OLD_OPTS"
      return 0
    }

    TODAY=$(date +%Y-%m-%d)
    LAST_CHECK_DATE=""
    if [[ -f "${CACHE_DATE}" ]]; then
      LAST_CHECK_DATE=$(cat "${CACHE_DATE}")
    fi

    # 今日已经检查过，直接退出
    if [[ "${LAST_CHECK_DATE}" == "${TODAY}" ]]; then
      eval "$OLD_OPTS"
      return 0
    fi

    # 2. 读取本地workflow版本，捕获plist读取异常
    LOCAL_VER=""
    if ! LOCAL_VER=$(/usr/libexec/PlistBuddy -c "Print version" "./info.plist" 2>/dev/null); then
      echo "[update] failed read local version from info.plist" >&2
      echo "${TODAY}" > "${CACHE_DATE}"
      eval "$OLD_OPTS"
      return 0
    fi

    # 3. 拉取远端manifest，捕获网络超时/失败
    MANIFEST_RAW=""
    if ! MANIFEST_RAW=$(curl -s --max-time 8 "${MANIFEST_URL}" 2>/dev/null); then
      echo "[update] curl fetch manifest failed (network error)" >&2
      echo "${TODAY}" > "${CACHE_DATE}"
      eval "$OLD_OPTS"
      return 0
    fi

    # 4. plutil解析json，捕获json格式错误
    REMOTE_VER=""
    DL_URL=""
    if ! REMOTE_VER=$(echo "${MANIFEST_RAW}" | plutil -extract version raw -o - - 2>/dev/null); then
      echo "[update] parse manifest: version field invalid / json broken" >&2
      echo "${TODAY}" > "${CACHE_DATE}"
      eval "$OLD_OPTS"
      return 0
    fi
    if ! DL_URL=$(echo "${MANIFEST_RAW}" | plutil -extract download_url raw -o - - 2>/dev/null); then
      echo "[update] parse manifest: download_url field missing" >&2
      echo "${TODAY}" > "${CACHE_DATE}"
      eval "$OLD_OPTS"
      return 0
    fi

    # 标记今日已完成检查（无论是否有新版本）
    echo "${TODAY}" > "${CACHE_DATE}"

    # 5. 读取忽略版本
    IGNORED_VER=""
    if [[ -f "${CACHE_IGNORE_VER}" ]]; then
      IGNORED_VER=$(cat "${CACHE_IGNORE_VER}")
    fi
    if [[ "${REMOTE_VER}" == "${IGNORED_VER}" ]]; then
      echo "[update] remote version ${REMOTE_VER} is ignored, skip" >&2
      eval "$OLD_OPTS"
      return 0
    fi

    # 6. 版本对比
    if version_gt "${REMOTE_VER}" "${LOCAL_VER}"; then
      echo "[update] new version found: ${REMOTE_VER}, local:${LOCAL_VER}" >&2
      # osascript 弹窗，捕获弹窗异常
      CHOICE=""
      if ! CHOICE=$(osascript <<EOF 2>/dev/null
set opt to button returned of (display dialog "发现新版本 ${REMOTE_VER}\n当前版本：${LOCAL_VER}" buttons {"Ignore this version", "Remind tomorrow", "Install now"} default button "Install now" with title "Alfred Workflow Update (Quickly Open Project With PyCharm)")
return opt
EOF
      ); then
        echo "[update] dialog popup failed" >&2
        eval "$OLD_OPTS"
        return 0
      fi

      case "${CHOICE}" in
        "Ignore this version")
          echo "${REMOTE_VER}" > "${CACHE_IGNORE_VER}"
          echo "[update] ignore version ${REMOTE_VER}" >&2
          ;;
        "Install now")
          echo "[update] start download workflow package" >&2
          TMP_WF=""
          # 【新增兜底】先尝试清理同名文件，防止残留旧文件干扰
          local temp_candidate="${TMPDIR}${TEMP_FILE_PREFIX}.alfredworkflow"
          rm -f "${temp_candidate}"
          if ! TMP_WF=$(mktemp "${TMPDIR}${TEMP_FILE_PREFIX}.alfredworkflow" 2>/dev/null); then
            echo "[update] failed create temp file(mktemp permission)" >&2
            eval "$OLD_OPTS"
            return 0
          fi
          # 原始静默curl，无进度通知
          if ! curl -sL --max-time 60 "${DL_URL}" -o "${TMP_WF}" 2>/dev/null; then
            echo "[update] download workflow failed" >&2
            rm -f "${TMP_WF}"
            eval "$OLD_OPTS"
            return 0
          fi
          echo "[update] temp file path: ${TMP_WF}" >&2
          ls -lh "${TMP_WF}" >&2
          open "${TMP_WF}"
          # 后台延时10秒删除临时文件，不阻塞主线程
#          (sleep 10; rm -f "${TMP_WF}") &
          ;;
        "Remind tomorrow")
          echo "[update] remind tomorrow, skip this time" >&2
          ;;
      esac
    fi

    # ✅ 函数正常执行完毕，恢复外层shell选项
    eval "$OLD_OPTS"
}
