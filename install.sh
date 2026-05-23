#!/usr/bin/env bash
# ============================================================
#  mpd2hls 一键远程安装脚本
# ------------------------------------------------------------
#  用法:
#    curl -fsSL https://raw.githubusercontent.com/judy-gotv/mpd2hls/main/install.sh | bash
#    或
#    wget -qO- https://raw.githubusercontent.com/judy-gotv/mpd2hls/main/install.sh | bash
#
#  非交互一键模式:
#    curl -fsSL ... | bash -s install      # 直接安装+启动
#    curl -fsSL ... | bash -s uninstall    # 直接卸载
#    curl -fsSL ... | bash -s update       # 拉最新二进制
# ============================================================
set -e

# ---------------- 配色 ----------------
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

log()   { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERR ]${NC} $*"; exit 1; }
step()  { echo -e "${MAGENTA}[STEP]${NC} ${BOLD}$*${NC}"; }

# ---------------- 默认配置 ----------------
INSTALL_DIR="${INSTALL_DIR:-/opt/mpd2hls}"
BIN_PATH="${INSTALL_DIR}/mpd2hls"
ENV_FILE="${INSTALL_DIR}/mpd2hls.env"
SERVICE_NAME="mpd2hls-panel"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

PANEL_PORT="${PANEL_PORT:-9527}"
PANEL_ADMIN_PATH="${PANEL_ADMIN_PATH:-/admin}"

# GitHub Releases - latest 自动指向最新版本
GH_REPO="${GH_REPO:-judy-gotv/mpd2hls}"
GH_RELEASE_TAG="${GH_RELEASE_TAG:-latest}"
if [ "$GH_RELEASE_TAG" = "latest" ]; then
  GH_BASE="https://github.com/${GH_REPO}/releases/latest/download"
else
  GH_BASE="https://github.com/${GH_REPO}/releases/download/${GH_RELEASE_TAG}"
fi

# 三个架构对应的二进制文件名（与 release 资产名一致）
URL_AMD64="${GH_BASE}/mpd2hls"
URL_ARM64="${GH_BASE}/mpd2hls-aarch64"
URL_ARMV7="${GH_BASE}/mpd2hls-armv7"

# ---------------- sudo 检测 ----------------
SUDO=""
if [ "$(id -u)" != "0" ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    error "当前非 root 用户且未安装 sudo，请用 root 执行或安装 sudo"
  fi
fi

# ---------------- 架构检测 ----------------
detect_arch() {
  local m
  m="$(uname -m)"
  case "$m" in
    x86_64|amd64)        echo "amd64" ;;
    aarch64|arm64)       echo "arm64" ;;
    armv7l|armv7|armhf)  echo "armv7" ;;
    *)                   echo "unknown" ;;
  esac
}

arch_url() {
  case "$1" in
    amd64) echo "$URL_AMD64" ;;
    arm64) echo "$URL_ARM64" ;;
    armv7) echo "$URL_ARMV7" ;;
    *)     echo "" ;;
  esac
}

# ---------------- 工具：包管理器抽象 ----------------
PM=""
detect_pm() {
  if   command -v apt-get >/dev/null 2>&1; then PM="apt"
  elif command -v dnf     >/dev/null 2>&1; then PM="dnf"
  elif command -v yum     >/dev/null 2>&1; then PM="yum"
  elif command -v apk     >/dev/null 2>&1; then PM="apk"
  elif command -v pacman  >/dev/null 2>&1; then PM="pacman"
  elif command -v zypper  >/dev/null 2>&1; then PM="zypper"
  else PM="unknown"
  fi
}

pkg_install() {
  detect_pm
  local pkg=""
  for spec in "$@"; do
    if [ "${spec%%:*}" = "$PM" ]; then
      pkg="${spec#*:}"
      break
    fi
  done
  [ -z "$pkg" ] && { warn "未识别的包管理器 ($PM)，跳过"; return 0; }
  case "$PM" in
    apt)    $SUDO apt-get update -y >/dev/null 2>&1 || true; $SUDO apt-get install -y $pkg ;;
    dnf)    $SUDO dnf install -y $pkg ;;
    yum)    $SUDO yum install -y $pkg ;;
    apk)    $SUDO apk add --no-cache $pkg ;;
    pacman) $SUDO pacman -Sy --noconfirm $pkg ;;
    zypper) $SUDO zypper install -y $pkg ;;
  esac
}

ensure_cmd() {
  local cmd="$1"; shift
  if command -v "$cmd" >/dev/null 2>&1; then return 0; fi
  warn "缺少命令 $cmd，正在自动安装..."
  pkg_install "$@"
  command -v "$cmd" >/dev/null 2>&1 || warn "$cmd 仍未安装，可能影响后续步骤"
}

# ---------------- 基础依赖 ----------------
prepare_basics() {
  step "检查基础工具 (curl/ca-certificates) ..."
  ensure_cmd curl apt:curl dnf:curl yum:curl apk:curl pacman:curl zypper:curl
  # ca-certificates 对 HTTPS 拉流是必须的
  case "$(detect_pm; echo $PM)" in
    apt)    $SUDO apt-get install -y ca-certificates >/dev/null 2>&1 || true ;;
    dnf|yum) $SUDO ${PM:-yum} install -y ca-certificates >/dev/null 2>&1 || true ;;
    apk)    $SUDO apk add --no-cache ca-certificates >/dev/null 2>&1 || true ;;
  esac
}

# ---------------- 准备目录 ----------------
prepare_dirs() {
  step "准备目录 $INSTALL_DIR ..."
  $SUDO mkdir -p "$INSTALL_DIR"
  $SUDO chmod 755 "$INSTALL_DIR"
  log "  - $INSTALL_DIR ✅"
}

# ---------------- 下载二进制 ----------------
download_binary() {
  local arch="$1"
  local url; url="$(arch_url "$arch")"
  [ -z "$url" ] && error "不支持的架构: $arch"

  step "下载 $arch 二进制 ..."
  log "  - URL: $url"
  local tmp="/tmp/mpd2hls-$arch.$$"
  rm -f "$tmp"
  if ! curl -fL --progress-bar -o "$tmp" "$url"; then
    error "下载失败，请检查网络或 GitHub 是否可访问"
  fi
  log "  - 已下载: $(du -h "$tmp" | cut -f1) -> $tmp"

  # 备份旧二进制
  if [ -f "$BIN_PATH" ]; then
    $SUDO cp -a "$BIN_PATH" "${BIN_PATH}.bak.$(date +%Y%m%d-%H%M%S)" || true
  fi

  $SUDO install -m 0755 "$tmp" "$BIN_PATH"
  rm -f "$tmp"
  log "  - 已安装到 $BIN_PATH ✅"
}

# ---------------- 写入环境变量配置文件 ----------------
init_env_file() {
  step "初始化环境配置 $ENV_FILE ..."
  if [ -f "$ENV_FILE" ]; then
    log "  - 已存在: $ENV_FILE ✅ (跳过覆盖，保留用户修改)"
    return
  fi
  $SUDO tee "$ENV_FILE" >/dev/null <<EOF
# ============================================================
# mpd2hls 运行配置 (由 install.sh 生成)
# 修改后执行: systemctl restart ${SERVICE_NAME}
# ============================================================

# ---------- 面板监听 ----------
# 默认只监听本机，如需公网访问请放在 HTTPS 反向代理后面
PANEL_ADDR=127.0.0.1:${PANEL_PORT}

# 内建 HTTPS 监听（两项必须同时设置）；留空时使用反向代理或仅监听 127.0.0.1
PANEL_TLS_CERT=
PANEL_TLS_KEY=

# 仅当确认已由 HTTPS 反向代理保护时，才允许面板直接监听公网地址
PANEL_ALLOW_INSECURE_PUBLIC_BIND=0

# Worker 远端编排默认开启；仅在可信内网/VPN 中需要安装或卸载 worker 时临时启用
PANEL_ENABLE_WORKER_ADMIN=1
PANEL_ADMIN_PATH=${PANEL_ADMIN_PATH}
PANEL_PROCESS_NAME=mpd2hls
PANEL_CHANNELS_FILE=./channels.json
PANEL_AUTH_FILE=./panel_auth.json
PANEL_AUDIT_LOG_FILE=./audit.log
# Panel/worker API token 文件；留空环境 token 时会自动生成并使用该文件
PANEL_API_TOKEN_FILE=./panel_api_token

# ---------- 默认账号 (仅首次生成 panel_auth.json 时生效) ----------
PANEL_ADMIN_USER=admin
# 留空时首次启动会随机生成临时密码并打印到 stderr/journal，登录后可在面板自行修改。
PANEL_ADMIN_PASS=

# 0=HTTP/HTTPS 都发 Cookie；1=仅 HTTPS
PANEL_COOKIE_SECURE=1

# 下游播放器 UA 白名单（空=不校验）
PANEL_PLAYER_USER_AGENT=""

# 日志与调试：0=只保留启停/退出/错误，1=完整调试日志
MPD2HLS_LOG_DEBUG=0

# ---------- 网络超时（直播建议） ----------
MPD2HLS_READ_TIMEOUT_SEC=90
MPD2HLS_REQUEST_TIMEOUT_SEC=90

# ---------- 直播对齐 / 重锚（默认偏离值） ----------
MPD2HLS_AV_ALIGN_WIDE_MAX_GAP=64
MPD2HLS_SID_MISMATCH_ALLOW_SAME_IDX_MAX_DIFF_MS=800
MPD2HLS_SID_MISMATCH_ADAPTIVE_MAX_DIFF_MS=2500
MPD2HLS_REANCHOR_AFTER_SKIPS=0
EOF
  $SUDO chmod 600 "$ENV_FILE"
  log "  - 已写入并设置权限 600 ✅"
}

# ---------------- 写入 systemd 服务 ----------------
write_systemd_service() {
  step "写入 systemd 服务 $SERVICE_FILE ..."
  $SUDO tee "$SERVICE_FILE" >/dev/null <<EOF
[Unit]
Description=mpd2hls Panel Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${INSTALL_DIR}
EnvironmentFile=${ENV_FILE}
ExecStart=${BIN_PATH}
Restart=on-failure
RestartSec=3
LimitNOFILE=1048576
# 仅允许写入安装目录与临时目录
ProtectSystem=full
PrivateTmp=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF
  $SUDO systemctl daemon-reload
  $SUDO systemctl enable "$SERVICE_NAME" >/dev/null 2>&1 || true
  log "  - 已写入并启用开机自启 ✅"
}

# ---------------- 启停 ----------------
start_service() {
  step "启动 $SERVICE_NAME ..."
  $SUDO systemctl restart "$SERVICE_NAME"
  sleep 2
  if $SUDO systemctl is-active --quiet "$SERVICE_NAME"; then
    log "  - 服务运行中 ✅"
  else
    warn "  - 服务启动失败，请查看日志:"
    $SUDO journalctl -u "$SERVICE_NAME" -n 30 --no-pager || true
  fi
}

stop_service() {
  step "停止 $SERVICE_NAME ..."
  $SUDO systemctl stop "$SERVICE_NAME" 2>/dev/null || true
  log "  - 已停止"
}

# ---------------- 提取首次启动密码 ----------------
show_admin_password() {
  if [ -f "${INSTALL_DIR}/panel_auth.json" ]; then
    # 已存在 auth 文件，密码已被哈希持久化
    return
  fi
  # 等待日志输出
  local i=0
  local line=""
  while [ $i -lt 10 ]; do
    line=$($SUDO journalctl -u "$SERVICE_NAME" --no-pager 2>/dev/null | grep -i "generated one-time temporary password" | tail -1 || true)
    [ -n "$line" ] && break
    sleep 1
    i=$((i+1))
  done
  if [ -n "$line" ]; then
    echo -e "${YELLOW}${BOLD}$line${NC}"
  fi
}

# ---------------- 完成横幅 ----------------
print_banner() {
  local arch="$1"
  local ip
  ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
  [ -z "$ip" ] && ip="$(hostname -i 2>/dev/null | awk '{print $1}')"
  [ -z "$ip" ] && ip="<服务器 IP>"

  echo
  echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║   ✅  mpd2hls 安装并启动完成 (${arch})         ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
  echo -e "  ${BOLD}访问地址${NC}"
  echo -e "    本机面板 : ${CYAN}http://127.0.0.1:${PANEL_PORT}${PANEL_ADMIN_PATH}${NC}"
  echo -e "    若已配置反代/公网: ${CYAN}https://<你的域名>${PANEL_ADMIN_PATH}${NC}"
  echo -e "  ${BOLD}文件位置${NC}"
  echo -e "    二进制   : ${BIN_PATH}"
  echo -e "    配置     : ${ENV_FILE}   ${YELLOW}(修改后 systemctl restart ${SERVICE_NAME})${NC}"
  echo -e "    频道     : ${INSTALL_DIR}/channels.json"
  echo -e "    认证     : ${INSTALL_DIR}/panel_auth.json"
  echo -e "    日志     : journalctl -u ${SERVICE_NAME} -f"
  echo -e "${GREEN}--------------------------------------------${NC}"
  echo -e "  🔐  ${YELLOW}${BOLD}默认账号${NC}"
  echo -e "      用户名 : ${CYAN}${BOLD}admin${NC}"
  echo -e "      密  码 : ${YELLOW}首次启动随机生成，请查看下方日志：${NC}"
  echo
  show_admin_password
  echo
  echo -e "      ${BOLD}手动查看密码命令：${NC}"
  echo -e "        ${CYAN}journalctl -u ${SERVICE_NAME} | grep -i 'temporary password'${NC}"
  echo -e "  ⚠️   ${YELLOW}登录后请立即在面板「账号设置」中修改密码！${NC}"
  echo -e "${GREEN}--------------------------------------------${NC}"
  echo -e "  ${BOLD}常用命令${NC}"
  echo -e "    systemctl start|stop|restart|status ${SERVICE_NAME}"
  echo -e "    journalctl -u ${SERVICE_NAME} -f                # 实时日志"
  echo -e "    bash $0 menu                                    # 交互菜单"
  echo -e "    bash $0 update                                  # 升级到最新版"
  echo -e "    bash $0 uninstall                               # 卸载"
  echo -e "${GREEN}============================================${NC}"
}

# ---------------- 主动作 ----------------
do_install() {
  local arch="${1:-}"
  if [ -z "$arch" ] || [ "$arch" = "auto" ]; then
    arch="$(detect_arch)"
    [ "$arch" = "unknown" ] && error "无法识别架构: $(uname -m)，请手动指定 amd64/arm64/armv7"
    log "自动检测架构: ${BOLD}$arch${NC} ($(uname -m))"
  fi
  prepare_basics
  prepare_dirs
  download_binary "$arch"
  init_env_file
  write_systemd_service
  start_service
  print_banner "$arch"
}

do_update() {
  log "更新 = 拉取最新二进制 + 重启服务（配置文件保留）"
  local arch; arch="$(detect_arch)"
  [ "$arch" = "unknown" ] && error "无法识别架构: $(uname -m)"
  download_binary "$arch"
  # 服务文件可能也要同步（避免老版本字段过时）
  write_systemd_service
  start_service
  log "✅ 更新完成"
  $SUDO systemctl status "$SERVICE_NAME" --no-pager -n 5 || true
}

do_uninstall() {
  echo -e "${RED}╔════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║   ⚠️   卸载 mpd2hls                         ║${NC}"
  echo -e "${RED}╚════════════════════════════════════════════╝${NC}"
  echo -e "  将执行:"
  echo -e "    1) 停止并禁用 systemd 服务"
  echo -e "    2) 删除 ${SERVICE_FILE}"
  echo -e "    3) 删除 ${INSTALL_DIR} (含二进制 / 频道 / 认证 / 日志)"
  echo
  read -r -p "确认输入 YES 继续: " ans
  if [ "$ans" != "YES" ]; then
    warn "已取消"
    return
  fi
  $SUDO systemctl stop "$SERVICE_NAME" 2>/dev/null || true
  $SUDO systemctl disable "$SERVICE_NAME" 2>/dev/null || true
  $SUDO rm -f "$SERVICE_FILE"
  $SUDO systemctl daemon-reload || true
  $SUDO rm -rf "$INSTALL_DIR"
  log "✅ 已卸载并清理完毕"
}

do_status() {
  echo "============================================"
  echo "  mpd2hls 服务状态"
  echo "============================================"
  if $SUDO systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
    echo -e "  状态  : ${GREEN}运行中${NC}"
  else
    echo -e "  状态  : ${RED}未运行${NC}"
  fi
  echo "  端口  : $PANEL_PORT"
  echo "  目录  : $INSTALL_DIR"
  echo "  二进制: $BIN_PATH ($([ -f "$BIN_PATH" ] && du -h "$BIN_PATH" | cut -f1 || echo '未安装'))"
  echo "  配置  : $ENV_FILE"
  echo "  服务  : $SERVICE_FILE"
  echo "--------------------------------------------"
  $SUDO systemctl status "$SERVICE_NAME" --no-pager -n 10 2>/dev/null || true
  echo "============================================"
}

do_logs() {
  echo "[Ctrl+C 退出查看]"
  $SUDO journalctl -u "$SERVICE_NAME" -f --no-pager
}

do_show_password() {
  step "查找首次启动随机密码 ..."
  local line
  line=$($SUDO journalctl -u "$SERVICE_NAME" --no-pager 2>/dev/null | grep -i "generated one-time temporary password" | tail -1 || true)
  if [ -n "$line" ]; then
    echo -e "${YELLOW}${BOLD}$line${NC}"
  else
    warn "未在日志中找到随机密码记录。可能原因："
    echo "  1) 你已经在 $ENV_FILE 里设置了 PANEL_ADMIN_PASS=xxx"
    echo "  2) panel_auth.json 已存在（密码已被持久化哈希存储）"
    echo "  3) 日志已轮转，可尝试: journalctl -u $SERVICE_NAME --since '2 hours ago'"
    echo ""
    echo "如需重置密码："
    echo "  systemctl stop $SERVICE_NAME"
    echo "  rm -f $INSTALL_DIR/panel_auth.json"
    echo "  # 编辑 $ENV_FILE 把 PANEL_ADMIN_PASS 留空（或设为你想要的密码）"
    echo "  systemctl start $SERVICE_NAME"
    echo "  bash $0 password   # 再次查看"
  fi
}

# ---------------- 菜单 ----------------
show_menu() {
  clear 2>/dev/null || true
  local arch; arch="$(detect_arch)"
  echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║${NC}     ${BOLD}mpd2hls  一键远程安装/管理${NC}              ${BLUE}║${NC}"
  echo -e "${BLUE}║${NC}     ${CYAN}https://github.com/${GH_REPO}${NC}            ${BLUE}║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
  echo -e "  当前架构 : ${CYAN}${arch}${NC} ($(uname -m))"
  echo -e "  安装目录 : ${CYAN}${INSTALL_DIR}${NC}"
  echo -e "  端  口   : ${CYAN}${PANEL_PORT}${NC}  路径: ${CYAN}${PANEL_ADMIN_PATH}${NC}"
  echo -e "${BLUE}--------------------------------------------${NC}"
  echo -e "  ${GREEN}1)${NC}  一键安装 (自动识别架构)        ${YELLOW}★ 推荐${NC}"
  echo -e "  ${GREEN}2)${NC}  指定架构安装 (amd64 / arm64 / armv7)"
  echo -e "  ${GREEN}3)${NC}  更新到最新版 (重新下载二进制)"
  echo -e "  ${GREEN}4)${NC}  启动服务"
  echo -e "  ${GREEN}5)${NC}  停止服务"
  echo -e "  ${GREEN}6)${NC}  查看运行状态"
  echo -e "  ${GREEN}7)${NC}  查看实时日志"
  echo -e "  ${GREEN}8)${NC}  查看首次启动随机密码"
  echo -e "  ${RED}9)${NC}  卸载 (清理所有文件)"
  echo -e "  ${YELLOW}0)${NC}  退出"
  echo -e "${BLUE}============================================${NC}"
}

menu_loop() {
  while true; do
    show_menu
    read -r -p "请选择 [0-9]: " choice
    case "$choice" in
      1) do_install auto;  read -r -p "按回车返回菜单..." _ ;;
      2)
         echo "  a) amd64    b) arm64    c) armv7"
         read -r -p "选择 [a/b/c]: " a
         case "$a" in
           a|A|amd64) do_install amd64 ;;
           b|B|arm64) do_install arm64 ;;
           c|C|armv7) do_install armv7 ;;
           *) warn "无效选择" ;;
         esac
         read -r -p "按回车返回菜单..." _ ;;
      3) do_update;       read -r -p "按回车返回菜单..." _ ;;
      4) start_service;   read -r -p "按回车返回菜单..." _ ;;
      5) stop_service;    read -r -p "按回车返回菜单..." _ ;;
      6) do_status;       read -r -p "按回车返回菜单..." _ ;;
      7) do_logs ;;
      8) do_show_password; read -r -p "按回车返回菜单..." _ ;;
      9) do_uninstall;    read -r -p "按回车返回菜单..." _ ;;
      0) echo "Bye 👋"; exit 0 ;;
      *) warn "无效选择: $choice"; sleep 1 ;;
    esac
  done
}

# ---------------- 入口 ----------------
case "${1:-}" in
  install)            do_install "${2:-auto}" ;;
  install-amd64)      do_install amd64 ;;
  install-arm64)      do_install arm64 ;;
  install-armv7)      do_install armv7 ;;
  update)             do_update ;;
  start)              start_service ;;
  stop)               stop_service ;;
  restart)            stop_service; start_service ;;
  status)             do_status ;;
  logs)               do_logs ;;
  password|passwd)    do_show_password ;;
  uninstall|remove)   do_uninstall ;;
  menu|"")            menu_loop ;;
  -h|--help|help)
    cat <<EOF
mpd2hls 一键安装脚本

用法:
  bash $0                  # 交互菜单 (默认)
  bash $0 install [arch]   # 安装 (arch: auto|amd64|arm64|armv7)
  bash $0 update           # 更新到最新版
  bash $0 start|stop       # 启停服务
  bash $0 restart          # 重启服务
  bash $0 status           # 查看状态
  bash $0 logs             # 实时日志
  bash $0 password         # 查看首次启动随机密码
  bash $0 uninstall        # 卸载

环境变量（可在执行前 export 覆盖默认值）:
  INSTALL_DIR=/opt/mpd2hls       # 安装目录
  PANEL_PORT=9527                # 面板端口
  PANEL_ADMIN_PATH=/admin        # 面板路径
  GH_REPO=judy-gotv/mpd2hls      # GitHub 仓库
  GH_RELEASE_TAG=latest          # 版本号，如 0.2.33

示例：
  GH_RELEASE_TAG=0.2.33 bash $0 install
  PANEL_PORT=18080 bash $0 install amd64
EOF
    ;;
  *) error "未知命令: $1   (使用 'bash $0 help' 查看帮助)" ;;
esac
