#!/bin/sh
# ============================================================
#  OpenWRT Dashboard — install.sh
#  Works on OpenWRT 23.x / 24.x / 25.x (apk or opkg)
#
#  One-liner install (run directly on the router):
#    wget -qO- https://raw.githubusercontent.com/Anilexis/openwrt-darkboard/main/install.sh | sh
#
#  Or download first, then run:
#    wget https://raw.githubusercontent.com/Anilexis/openwrt-darkboard/main/install.sh
#    sh install.sh
# ============================================================
set -e

DASH_SRC="dashboard.html"
DASH_DST="/www/dashboard.html"
ACL_DST="/usr/share/rpcd/acl.d/dashboard.json"
ACL_SRC="dashboard.json"
REPO_URL="https://raw.githubusercontent.com/Anilexis/openwrt-darkboard/main"

RED='\033[0;31m'; GRN='\033[0;32m'; YEL='\033[1;33m'; NC='\033[0m'
ok()  { printf "${GRN}[OK]${NC} %s\n" "$1"; }
err() { printf "${RED}[ERR]${NC} %s\n" "$1"; exit 1; }
ask() { printf "${YEL}?${NC} %s: " "$1"; read -r ans; echo "$ans"; }
info(){ printf "${YEL}[i]${NC} %s\n" "$1"; }

# ============================================================
# 0. Detect package manager
# ============================================================
if command -v apk >/dev/null 2>&1; then
  PKG_MGR="apk"
elif command -v opkg >/dev/null 2>&1; then
  PKG_MGR="opkg"
else
  err "Neither apk nor opkg found. Is this really OpenWRT?"
fi
ok "Package manager: $PKG_MGR"

# ============================================================
# 1. Collect settings
# ============================================================
echo ""
info "========================================"
info "  Dashboard setup — enter your settings "
info "========================================"
echo ""

ROUTER_IP=$(ask "Router IP [default: 192.168.1.1]")
[ -z "$ROUTER_IP" ] && ROUTER_IP="192.168.1.1"

LUCI_PASS=$(ask "LuCI/root password (leave empty if none)")

MIHOMO_SECRET=$(ask "Mihomo external-controller secret (leave empty if none)")

ADG_ENABLE=$(ask "Enable AdGuard Home integration? [y/N]")
ADG_USER=""; ADG_PASS=""; ADG_PORT="3030"
if [ "$ADG_ENABLE" = "y" ] || [ "$ADG_ENABLE" = "Y" ]; then
  ADG_USER=$(ask "AdGuard admin username [default: admin]")
  [ -z "$ADG_USER" ] && ADG_USER="admin"
  ADG_PASS=$(ask "AdGuard admin password (leave empty if none)")
  ADG_PORT=$(ask "AdGuard port [default: 3030]")
  [ -z "$ADG_PORT" ] && ADG_PORT="3030"
fi

WIFI_AP=$(ask "External WiFi AP IP (e.g. 192.168.1.100, leave empty to use local wireless or disable)")
WIFI_AP_PORT=""
WIFI_AP_HTTPS="true"
if [ -n "$WIFI_AP" ]; then
  WIFI_AP_PORT=$(ask "WiFi AP admin port (e.g. 8443 or 80, leave empty to hide link)")
  _HTTPS=$(ask "Use HTTPS for AP admin link? (Y/n)")
  [ "$_HTTPS" = "n" ] || [ "$_HTTPS" = "N" ] && WIFI_AP_HTTPS="false"
fi

MIHOMO_PORT=$(ask "Mihomo API port [default: 9090]")
[ -z "$MIHOMO_PORT" ] && MIHOMO_PORT="9090"

echo ""
info "Settings:"
info "  Router:         $ROUTER_IP"
info "  Mihomo API:     $ROUTER_IP:$MIHOMO_PORT"
info "  AdGuard:        ${ADG_ENABLE:-N} (port $ADG_PORT)"
info "  WiFi AP:        ${WIFI_AP:-local/disabled}${WIFI_AP_PORT:+ :${WIFI_AP_PORT}}"
echo ""

CONFIRM=$(ask "Apply? [Y/n]")
[ "$CONFIRM" = "n" ] || [ "$CONFIRM" = "N" ] && { info "Aborted."; exit 0; }

# ============================================================
# 2. Download files from GitHub (if not already present locally)
# ============================================================
if [ ! -f "$DASH_SRC" ] || [ ! -f "$ACL_SRC" ]; then
  info "Local files not found — downloading from GitHub..."
  wget -q -O "$DASH_SRC" "$REPO_URL/dashboard.html" || err "Failed to download dashboard.html"
  wget -q -O "$ACL_SRC"  "$REPO_URL/dashboard.json" || err "Failed to download dashboard.json"
  ok "Files downloaded successfully"
else
  ok "Using local files"
fi

# ============================================================
# 3. Patch dashboard.html with user values
# ============================================================
cp "$DASH_SRC" /tmp/dashboard_install.html

sed -i "s|router:[[:space:]]*'http://192.168.1.1'|router:        'http://${ROUTER_IP}'|g" /tmp/dashboard_install.html
sed -i "s|luci_rpc:[[:space:]]*'http://192.168.1.1/ubus'|luci_rpc:      'http://${ROUTER_IP}/ubus'|g" /tmp/dashboard_install.html
sed -i "s|luci_pass:[[:space:]]*''|luci_pass:     '${LUCI_PASS}'|g" /tmp/dashboard_install.html
sed -i "s|mihomo_api:[[:space:]]*'http://192.168.1.1:9090'|mihomo_api:    'http://${ROUTER_IP}:${MIHOMO_PORT}'|g" /tmp/dashboard_install.html
sed -i "s|mihomo_secret:[[:space:]]*''|mihomo_secret: '${MIHOMO_SECRET}'|g" /tmp/dashboard_install.html
sed -i "s|adguard_host:[[:space:]]*'192.168.1.1'|adguard_host:  '${ROUTER_IP}'|g" /tmp/dashboard_install.html
sed -i "s|adguard_port:[[:space:]]*3030|adguard_port:  ${ADG_PORT}|g" /tmp/dashboard_install.html
sed -i "s|adguard_user:[[:space:]]*'admin'|adguard_user:  '${ADG_USER}'|g" /tmp/dashboard_install.html
sed -i "s|adguard_pass:[[:space:]]*''|adguard_pass:  '${ADG_PASS}'|g" /tmp/dashboard_install.html
sed -i "s|wifi_ap:[[:space:]]*''|wifi_ap:        '${WIFI_AP}'|g" /tmp/dashboard_install.html
sed -i "s|wifi_ap_port:[[:space:]]*''|wifi_ap_port:   '${WIFI_AP_PORT}'|g" /tmp/dashboard_install.html
sed -i "s|wifi_ap_https:[[:space:]]*true|wifi_ap_https:  ${WIFI_AP_HTTPS}|g" /tmp/dashboard_install.html
sed -i "s|http://192.168.1.1|http://${ROUTER_IP}|g" /tmp/dashboard_install.html

ok "dashboard.html patched"

# ============================================================
# 4. Install files
# ============================================================
cp /tmp/dashboard_install.html "$DASH_DST"
ok "Installed $DASH_DST"

cp "$ACL_SRC" "$ACL_DST"
ok "Installed $ACL_DST"

rm -f /tmp/dashboard_install.html

# ============================================================
# 5. Restart rpcd to apply ACL
# ============================================================
/etc/init.d/rpcd restart 2>/dev/null && ok "rpcd restarted" || info "rpcd restart failed — run: /etc/init.d/rpcd restart"

# ============================================================
# 6. Done
# ============================================================
echo ""
ok "========================================"
ok "  Installation complete!"
ok "========================================"
info "Open: http://${ROUTER_IP}/dashboard.html"
echo ""
