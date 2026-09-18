#!/usr/bin/env zsh

# ========== 【配置区，自行修改】 ==========
MANIFEST_URL="https://raw.githubusercontent.com/jeremy-jin/alfred-open-pycharm/master/src/manifest.json"
CACHE_DIR="${alfred_workflow_cache}"
CACHE_DATE="${CACHE_DIR}/last_check_date.txt"
CACHE_IGNORE_VER="${CACHE_DIR}/ignored_version.txt"
TEMP_FILE_PREFIX="com.jeremy.alfred.open-pycharm"
LOCK_FILE="${CACHE_DIR}/update-check.lock"
LOCK_TIMEOUT_SEC=120  # 锁超过2分钟，直接判定过期
LOG_FILE="${CACHE_DIR}/update-check.log"
MAX_LOG_KB=512        # 日志最大512KB，超过自动截断
# =========================================

# 获取脚本所在目录，不依赖alfred_workflow变量
SCRIPT_PATH="$0"
WORKFLOW_ROOT=$(dirname "${SCRIPT_PATH:A}")
INFO_PLIST="${WORKFLOW_ROOT}/info.plist"

# 兜底：alfred_workflow_cache为空，自动构造缓存目录
if [[ -z "${alfred_workflow_cache:-}" ]]; then
  if [[ -n "${alfred_workflow_bundleid:-}" ]]; then
    CACHE_DIR="${HOME}/Library/Caches/com.runningwithcrayons.Alfred/Workflow Data/${alfred_workflow_bundleid}"
  else
    CACHE_DIR="${WORKFLOW_ROOT}/.update_cache"
  fi
  # 同步更新相关文件路径
  LOCK_FILE="${CACHE_DIR}/update-check.lock"
  CACHE_DATE="${CACHE_DIR}/last_check_date.txt"
  CACHE_IGNORE_VER="${CACHE_DIR}/ignored_version.txt"
  LOG_FILE="${CACHE_DIR}/update-check.log"
fi

# 日志打印函数：同时输出stderr + 写入日志，带时间戳
log_print() {
    local ts
    ts=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[${ts}] $1" >&2
    echo "[${ts}] $1" >> "${LOG_FILE}"
}

# 日志轮转：超过MAX_LOG_KB则清空日志
rotate_log() {
    mkdir -p "${CACHE_DIR}"
    if [[ -f "${LOG_FILE}" ]]; then
        local file_size
        file_size=$(du -k "${LOG_FILE}" | cut -f1)
        if (( file_size > MAX_LOG_KB )); then
            log_print "Log file too big, truncate log."
            > "${LOG_FILE}"
        fi
    fi
}

# 版本比较函数：version_gt A B，A>B 返回0(true)
version_gt() {
  test "$(printf '%s\n' "$@" | sort -V | head -n1)" != "$1"
}

# 清理锁文件函数，trap回调
cleanup_lock() {
  if [[ -f "${LOCK_FILE}" ]]; then
    local stored_pid
    stored_pid=$(cat "${LOCK_FILE}" 2>/dev/null || echo "")
    if [[ "${stored_pid}" == "$$" ]]; then
      rm -f "${LOCK_FILE}"
      log_print "lock cleaned up, pid $$"
    fi
  fi
}

# 【核心更新检查函数】
check_workflow_update() {
    # 保存当前shell所有选项
    local OLD_OPTS
    OLD_OPTS=$(set +o)
    # 函数内开启严格模式
    set -euo pipefail

    # 注册信号捕获：收到中断/终止信号，自动清理锁
    trap cleanup_lock SIGINT SIGTERM EXIT

    # 1. 创建缓存目录
    mkdir -p "${CACHE_DIR}" || {
      log_print "failed to create cache dir"
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
      log_print "Already checked today, skip."
      eval "$OLD_OPTS"
      return 0
    fi

    # 2. 读取本地workflow版本
    LOCAL_VER=""
    if ! LOCAL_VER=$(/usr/libexec/PlistBuddy -c "Print version" "${INFO_PLIST}" 2>/dev/null); then
      log_print "failed read local version from ${INFO_PLIST}"
      echo "${TODAY}" > "${CACHE_DATE}"
      eval "$OLD_OPTS"
      return 0
    fi
    log_print "Local workflow version: ${LOCAL_VER}"

    # 3. 拉取远端manifest
    MANIFEST_RAW=""
    if ! MANIFEST_RAW=$(curl -s --max-time 8 "${MANIFEST_URL}" 2>/dev/null); then
      log_print "curl fetch manifest failed (network error)"
      echo "${TODAY}" > "${CACHE_DATE}"
      eval "$OLD_OPTS"
      return 0
    fi

    # 4. 解析json
    REMOTE_VER=""
    DL_URL=""
    if ! REMOTE_VER=$(echo "${MANIFEST_RAW}" | plutil -extract version raw -o - - 2>/dev/null); then
      log_print "parse manifest version failed / json broken"
      echo "${TODAY}" > "${CACHE_DATE}"
      eval "$OLD_OPTS"
      return 0
    fi
    if ! DL_URL=$(echo "${MANIFEST_RAW}" | plutil -extract download_url raw -o - - 2>/dev/null); then
      log_print "parse manifest download_url failed"
      echo "${TODAY}" > "${CACHE_DATE}"
      eval "$OLD_OPTS"
      return 0
    fi
    log_print "Remote manifest version: ${REMOTE_VER}"

    # 标记今日已完成检查
    echo "${TODAY}" > "${CACHE_DATE}"

    # 5. 读取忽略版本
    IGNORED_VER=""
    if [[ -f "${CACHE_IGNORE_VER}" ]]; then
      IGNORED_VER=$(cat "${CACHE_IGNORE_VER}")
    fi
    if [[ "${REMOTE_VER}" == "${IGNORED_VER}" ]]; then
      log_print "remote version ${REMOTE_VER} ignored, skip"
      eval "$OLD_OPTS"
      return 0
    fi

    # 6. 版本对比
    if version_gt "${REMOTE_VER}" "${LOCAL_VER}"; then
      log_print "new version found: ${REMOTE_VER}, local:${LOCAL_VER}"
      # osascript弹窗，三个选项
      CHOICE=""
      if ! CHOICE=$(osascript <<EOF 2>/dev/null
set opt to button returned of (display dialog "发现新版本 ${REMOTE_VER}
当前版本：${LOCAL_VER}" buttons {"Ignore this version", "Remind tomorrow", "Install now"} default button "Install now" with title "Alfred Workflow Update (Quickly Open Project With PyCharm)")
return opt
EOF
      ); then
        log_print "dialog popup failed or user closed window"
        eval "$OLD_OPTS"
        return 0
      fi

      case "${CHOICE}" in
        "Ignore this version")
          echo "${REMOTE_VER}" > "${CACHE_IGNORE_VER}"
          log_print "ignore this version ${REMOTE_VER}"
          ;;
        "Install now")
          log_print "start download workflow package"
          TMP_WF=""
          local temp_candidate="${TMPDIR}${TEMP_FILE_PREFIX}.alfredworkflow"
          rm -f "${temp_candidate}"
          if ! TMP_WF=$(mktemp "${TMPDIR}${TEMP_FILE_PREFIX}.alfredworkflow"); then
            log_print "failed create temp file(mktemp permission)"
            eval "$OLD_OPTS"
            return 0
          fi

          local curl_stderr
          local curl_rc
          curl_stderr=$(mktemp)
          curl -sL --max-time 60 "${DL_URL}" -o "${TMP_WF}" 2>"${curl_stderr}"
          curl_rc=$?

          if [[ ${curl_rc} -ne 0 ]]; then
            local curl_err_msg
            curl_err_msg=$(cat "${curl_stderr}")
            local human_msg=""
            case ${curl_rc} in
              6) human_msg="DNS域名解析失败" ;;
              7) human_msg="无法连接远端服务器" ;;
              22) human_msg="HTTP返回错误码(404/403等)" ;;
              28) human_msg="下载超时" ;;
              35) human_msg="SSL证书异常" ;;
              *) human_msg="未知网络错误" ;;
            esac
            log_print "download workflow failed: ${human_msg}, curl_rc=${curl_rc}, raw: ${curl_err_msg}"
            rm -f "${TMP_WF}" "${curl_stderr}"
            eval "$OLD_OPTS"
            return 0
          fi
          rm -f "${curl_stderr}"

          log_print "temp file path: ${TMP_WF}"
          open "${TMP_WF}"
          ;;
        "Remind tomorrow")
          log_print "remind tomorrow, skip"
          ;;
      esac
    fi

    eval "$OLD_OPTS"
    return 0
}

# ====================== 后台入口：带时间戳的锁校验 ======================
run_background_check() {
    mkdir -p "${CACHE_DIR}"
    rotate_log
    local now
    now=$(date +%s)

    log_print "=== Start background version check ==="

    # 检查锁文件
    if [[ -f "${LOCK_FILE}" ]]; then
        local stored_pid stored_ts
        # 锁文件格式：第一行PID，第二行创建时间戳
        stored_pid=$(head -n1 "${LOCK_FILE}" 2>/dev/null || echo "")
        stored_ts=$(sed -n '2p' "${LOCK_FILE}" 2>/dev/null || echo "0")

        local age=$(( now - stored_ts ))

        # 判断：进程存活 并且 锁未超时 → 直接退出
        if [[ -n "${stored_pid}" && "${stored_ts}" != "0" ]]; then
            if kill -0 "${stored_pid}" 2>/dev/null && [[ ${age} -lt ${LOCK_TIMEOUT_SEC} ]]; then
                log_print "another task running, pid:${stored_pid}, skip"
                return 0
            fi
        fi
        # 进程已死 / 锁超时 → 清理过期锁
        log_print "stale lock found, remove old lock"
        rm -f "${LOCK_FILE}"
    fi

    # 写入锁：PID + 当前时间戳
    echo -e "$$\n${now}" > "${LOCK_FILE}"
    log_print "Create lock file, pid: $$"

    # 执行更新逻辑
    check_workflow_update

    # 任务正常结束，清理锁（trap也会兜底清理）
    rm -f "${LOCK_FILE}"
    log_print "=== Background check finished ==="
}

# 后台执行，不阻塞Alfred主线程
#run_background_check &
