#!/bin/sh
# OpenWRT Dashboard installer
set -e

DASH_SRC="dashboard.html"
DASH_DST="/www/dashboard.html"
ACL_DST="/usr/share/rpcd/acl.d/dashboard.json"
ACL_SRC="dashboard.json"
REPO_URL="https://raw.githubusercontent.com/Anilexis/openwrt-darkboard/main"

RED=$(printf '\033[0;31m')
GRN=$(printf '\033[0;32m')
YEL=$(printf '\033[1;33m')
NC=$(printf '\033[0m')

ok()   { printf "${GRN}[OK]${NC} %s\n" "$1"; }
err()  { printf "${RED}[ERR]${NC} %s\n" "$1"; exit 1; }
ask() { printf "${YEL}[?]${NC} %s " "$1" >/dev/tty; read -r ans < /dev/tty; echo "$ans"; }
info() { printf "${YEL}[i]${NC} %s\n" "$1"; }
TITLE(){ printf "\n${GRN}===  %s  ===${NC}\n" "$*"; }

# sed escape helper escapes & \ / for use in sed replacement strings
escape_sed(){ printf '%s' "$1" | sed 's/[&\\/]/\\&/g'; }

# ============================================================ detect package manager
TITLE "Checking system"
if   command -v apk  >/dev/null 2>&1; then PKGMGR="apk"
elif command -v opkg >/dev/null 2>&1; then PKGMGR="opkg"
else err "Neither apk nor opkg found. Is this really OpenWRT?"; fi
ok "Package manager: $PKGMGR"

# ============================================================ gather settings
TITLE "Configuration"
echo
info "Dashboard setup - enter your settings"
info ""

ROUTER_IP=$(ask "Router IP [default: 192.168.1.1]:")
[ -z "$ROUTER_IP" ] && ROUTER_IP="192.168.1.1"

#validate IP format
echo "$ROUTER_IP" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' \
  || err "Invalid IP address: $ROUTER_IP"

ADG_ENABLE=$(ask "Enable AdGuard Home integration? [y/N]:")
ADG_USER="admin"
ADG_PASS=""
ADG_PORT="3003"
#only ask AdGuard details if enabled
if [ "$ADG_ENABLE" = "y" ] || [ "$ADG_ENABLE" = "Y" ]; then
  ADG_USER=$(ask "AdGuard admin username [default: admin]:")
  [ -z "$ADG_USER" ] && ADG_USER="admin"
  ADG_PASS=$(ask "AdGuard admin password:")
  ADG_PORT=$(ask "AdGuard port [default: 3003]:")
  [ -z "$ADG_PORT" ] && ADG_PORT="3003"
fi

WIFI_AP=$(ask "External WiFi AP IP (e.g. 192.168.1.4), leave empty to disable:")
WIFI_AP_USER="admin"
WIFI_AP_PASS=""
WIFI_AP_PORT="80"
WIFI_AP_HTTPS="false"
if [ -n "$WIFI_AP" ]; then
  WIFI_AP_USER=$(ask "WiFi AP admin username [default: admin]:")
  [ -z "$WIFI_AP_USER" ] && WIFI_AP_USER="admin"
  WIFI_AP_PASS=$(ask "WiFi AP admin password (leave empty to be prompted at dashboard open):")
  WIFI_AP_PORT=$(ask "WiFi AP admin port [default: 80]:")
  [ -z "$WIFI_AP_PORT" ] && WIFI_AP_PORT="80"
  HTTPS=$(ask "Use HTTPS for AP admin link? [y/N]:")
  [ "$HTTPS" = "y" ] || [ "$HTTPS" = "Y" ] && WIFI_AP_HTTPS="true" || WIFI_AP_HTTPS="false"
fi

MIHOMO_PORT=$(ask "Mihomo API port [default: 9090]:")
[ -z "$MIHOMO_PORT" ] && MIHOMO_PORT="9090"

echo
info "Settings:"
info "  Router:   $ROUTER_IP"
info "  Mihomo:   $ROUTER_IP:$MIHOMO_PORT"
info "  AdGuard:  ${ADG_ENABLE:-N}  port=$ADG_PORT"
info "  WiFi AP:  ${WIFI_AP:-disabled}  port=$WIFI_AP_PORT  https=$WIFI_AP_HTTPS"
echo

CONFIRM=$(ask "Apply? [Y/n]:")
[ "$CONFIRM" = "n" ] || [ "$CONFIRM" = "N" ] && { info "Aborted."; exit 0; }

# ============================================================ download files if needed
TITLE "Files"
if [ ! -f "$DASH_SRC" ] || [ ! -f "$ACL_SRC" ]; then
  info "Local files not found â€” downloading from GitHub..."
  wget -q -O "$DASH_SRC" "$REPO_URL/dashboard.html" || err "Failed to download dashboard.html"
  wget -q -O "$ACL_SRC"  "$REPO_URL/dashboard.json" || err "Failed to download dashboard.json"
  ok "Files downloaded"
else
  ok "Using local files"
fi

# ============================================================ patch
TITLE "Patching"
cp "$DASH_SRC" /tmp/dashboard-install.html

# escape all user values before sed substitution
E_ROUTER_IP=$(escape_sed "$ROUTER_IP")
E_MIHOMO_PORT=$(escape_sed "$MIHOMO_PORT")
E_ADG_PORT=$(escape_sed "$ADG_PORT")
E_ADG_USER=$(escape_sed "$ADG_USER")
E_ADG_PASS=$(escape_sed "$ADG_PASS")
E_WIFI_AP=$(escape_sed "$WIFI_AP")
E_WIFI_AP_USER=$(escape_sed "$WIFI_AP_USER")
E_WIFI_AP_PASS=$(escape_sed "$WIFI_AP_PASS")
E_WIFI_AP_PORT=$(escape_sed "$WIFI_AP_PORT")

# Patch config values
sed -i "s|router:\s*'http://192.168.1.1'|router:        'http://${E_ROUTER_IP}'|g"     /tmp/dashboard-install.html
sed -i "s|luci_rpc:\s*'http://192.168.1.1/ubus'|luci_rpc:      'http://${E_ROUTER_IP}/ubus'|g" /tmp/dashboard-install.html
sed -i "s|mihomo_api:\s*'http://192.168.1.1:9090'|mihomo_api:    'http://${E_ROUTER_IP}:${E_MIHOMO_PORT}'|g" /tmp/dashboard-install.html
sed -i "s|adguard_host:\s*'192.168.1.1'|adguard_host:  '${E_ROUTER_IP}'|g"             /tmp/dashboard-install.html

# only patch AdGuard credentials if enabled
if [ "$ADG_ENABLE" = "y" ] || [ "$ADG_ENABLE" = "Y" ]; then
  sed -i "s|adguard_port:\s*3003,|adguard_port:  ${E_ADG_PORT},|g"                     /tmp/dashboard-install.html
  sed -i "s|adguard_user:\s*'admin'|adguard_user:  '${E_ADG_USER}'|g"                  /tmp/dashboard-install.html
  sed -i "s|adguard_pass:\s*''|adguard_pass:  '${E_ADG_PASS}'|g"                       /tmp/dashboard-install.html
fi

if [ -n "$WIFI_AP" ]; then
  sed -i "s|wifi_ap:\s*''|wifi_ap:       '${E_WIFI_AP}'|g"                             /tmp/dashboard-install.html
  sed -i "s|wifi_ap_user:\s*'admin'|wifi_ap_user:  '${E_WIFI_AP_USER}'|g"              /tmp/dashboard-install.html
  sed -i "s|wifi_ap_pass:\s*''|wifi_ap_pass:  '${E_WIFI_AP_PASS}'|g"                   /tmp/dashboard-install.html
  sed -i "s|wifi_ap_port:\s*80,|wifi_ap_port:  ${E_WIFI_AP_PORT},|g"                   /tmp/dashboard-install.html
  sed -i "s|wifi_ap_https:\s*false|wifi_ap_https: ${WIFI_AP_HTTPS}|g"                  /tmp/dashboard-install.html
fi

# Patch http://192.168.1.1 references for luci_pass
sed -i "s|'http://192.168.1.1'|'http://${E_ROUTER_IP}'|g"                              /tmp/dashboard-install.html

ok "dashboard.html patched"

# ============================================================ install
TITLE "Installing"
cp /tmp/dashboard-install.html "$DASH_DST"
ok "Installed $DASH_DST"
cp "$ACL_SRC" "$ACL_DST"
ok "Installed $ACL_DST"
rm -f /tmp/dashboard-install.html

# ============================================================ restart rpcd
TITLE "Restarting rpcd"
/etc/init.d/rpcd restart 2>/dev/null && ok "rpcd restarted" \
  || info "rpcd restart failed â€” run: /etc/init.d/rpcd restart"

# ============================================================ done
TITLE "Done"
echo
ok "Installation complete!"
info "Open: http://${ROUTER_IP}/dashboard.html"
echo