#!/bin/sh
# DarkBoard installer for OpenWRT
# Usage: wget -qO- https://raw.githubusercontent.com/Anilexis/openwrt-darkboard/main/install.sh | sh
# For test branch: wget -qO- https://raw.githubusercontent.com/Anilexis/openwrt-darkboard/test/install.sh | sh -s test
set -e

BRANCH="${1:-main}"

DASH_SRC="dashboard.html"
DASH_DST="/www/dashboard.html"
ACL_DST="/usr/share/rpcd/acl.d/dashboard.json"
ACL_SRC="dashboard.json"
REPO_URL="https://raw.githubusercontent.com/Anilexis/openwrt-darkboard/$BRANCH"

WORKDIR="/tmp/darkboard-install"
mkdir -p "$WORKDIR"

RED=$(printf '\033[0;31m')
GRN=$(printf '\033[0;32m')
YEL=$(printf '\033[1;33m')
CYN=$(printf '\033[0;36m')
NC=$(printf '\033[0m')

ok()   { printf "${GRN}[OK]${NC} %s\n" "$1"; }
err()  { printf "${RED}[ERR]${NC} %s\n" "$1"; exit 1; }
ask()  { printf "${YEL}[?]${NC} %s " "$2" >&2; read -r "$1" < /dev/tty; }
info() { printf "${YEL}[i]${NC} %s\n" "$1"; }
TITLE(){ printf "\n${GRN}=== %s ===${NC}\n" "$*"; }

# sed escape helper (escapes & \ / | for use in sed with | delimiter)
escape_sed(){ printf '%s' "$1" | sed 's/[&\\/|]/\\&/g'; }

# ============================================================ detect system
TITLE "Checking system"
if command -v apk >/dev/null 2>&1; then PKGMGR="apk"
elif command -v opkg >/dev/null 2>&1; then PKGMGR="opkg"
else err "Neither apk nor opkg found. Is this really OpenWRT?"; fi
ok "Package manager: $PKGMGR"

# ============================================================ gather settings
TITLE "Configuration"
echo
info "DarkBoard setup - enter your settings (press Enter to accept defaults)"
echo

# --- Router ---
ask ROUTER_IP "Router IP [default: 192.168.1.1]:"
[ -z "$ROUTER_IP" ] && ROUTER_IP="192.168.1.1"
echo "$ROUTER_IP" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' \
  || err "Invalid IP address: $ROUTER_IP"

# --- Mihomo ---
ask MIHOMO_PORT "Mihomo API port [default: 9090]:"
[ -z "$MIHOMO_PORT" ] && MIHOMO_PORT="9090"

# --- AdGuard Home ---
ask ADG_ENABLE "Enable AdGuard Home integration? [y/N]:"
ADG_PORT="3003"
if [ "$ADG_ENABLE" = "y" ] || [ "$ADG_ENABLE" = "Y" ]; then
  ask ADG_PORT "AdGuard port [default: 3003]:"
  [ -z "$ADG_PORT" ] && ADG_PORT="3003"
fi

# --- WiFi AP ---
ask WIFI_AP "External WiFi AP IP (e.g. 192.168.1.4), leave empty to disable:"
WIFI_AP_PORT="80"
WIFI_AP_HTTPS="false"
if [ -n "$WIFI_AP" ]; then
  ask WIFI_AP_PORT "WiFi AP admin port [default: 80]:"
  [ -z "$WIFI_AP_PORT" ] && WIFI_AP_PORT="80"
  ask HTTPS "Use HTTPS for AP admin link? [y/N]:"
  if [ "$HTTPS" = "y" ] || [ "$HTTPS" = "Y" ]; then
    WIFI_AP_HTTPS="true"
  else
    WIFI_AP_HTTPS="false"
  fi
fi

# --- Wired clients ---
echo
info "Client mapping: define wired clients for correct icons in CLIENTS panel."
info "Format: IP:TYPE:IFACE (type = pc|tv|ap, iface = ethN)"
info "Example: 192.168.1.2:pc:eth2"
info "Press Enter on empty line when done. Leave all empty to keep defaults."
echo

CLIENT_ENTRIES=""
while true; do
  ask CL_ENTRY "Client entry (or empty to finish):"
  [ -z "$CL_ENTRY" ] && break
  # Validate format
  echo "$CL_ENTRY" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:(pc|tv|ap):(eth[0-9]+)$' || {
    info "Invalid format: $CL_ENTRY (expected IP:TYPE:IFACE, e.g. 192.168.1.2:pc:eth2)"
    continue
  }
  CLIENT_ENTRIES="${CLIENT_ENTRIES}${CL_ENTRY}
"
done

# ============================================================ summary
echo
info "Settings:"
info "  Router:    $ROUTER_IP"
info "  Mihomo:    $ROUTER_IP:$MIHOMO_PORT"
info "  AdGuard:   ${ADG_ENABLE:-N} port=$ADG_PORT"
info "  WiFi AP:   ${WIFI_AP:-disabled} port=$WIFI_AP_PORT https=$WIFI_AP_HTTPS"
info "  Passwords are configured in the browser on first launch."
if [ -n "$CLIENT_ENTRIES" ]; then
  info "  Clients:"
  printf '%s' "$CLIENT_ENTRIES" | while IFS= read -r line; do
    [ -n "$line" ] && info "    $line"
  done
fi
echo

ask CONFIRM "Apply? [Y/n]:"
[ "$CONFIRM" = "n" ] || [ "$CONFIRM" = "N" ] && { info "Aborted."; exit 0; }

# ============================================================ download files from GitHub
TITLE "Downloading from GitHub"
wget -q -O "$WORKDIR/$DASH_SRC"                        "$REPO_URL/dashboard.html"                   || err "Failed to download dashboard.html"
wget -q -O "$WORKDIR/$ACL_SRC"                         "$REPO_URL/dashboard.json"                   || err "Failed to download dashboard.json"
wget -q -O "$WORKDIR/manifest.webmanifest"             "$REPO_URL/manifest.webmanifest"             || err "Failed to download manifest.webmanifest"
wget -q -O "$WORKDIR/sw.js"                            "$REPO_URL/sw.js"                            || err "Failed to download sw.js"
wget -q -O "$WORKDIR/web-app-manifest-192x192.png"     "$REPO_URL/web-app-manifest-192x192.png"     || err "Failed to download icon 192"
wget -q -O "$WORKDIR/web-app-manifest-512x512.png"     "$REPO_URL/web-app-manifest-512x512.png"     || err "Failed to download icon 512"
wget -q -O "$WORKDIR/favicon.ico"                      "$REPO_URL/favicon.ico"                      || err "Failed to download favicon.ico"
wget -q -O "$WORKDIR/favicon.svg"                      "$REPO_URL/favicon.svg"                      || err "Failed to download favicon.svg"
wget -q -O "$WORKDIR/favicon-96x96.png"                "$REPO_URL/favicon-96x96.png"                || err "Failed to download favicon-96x96.png"
wget -q -O "$WORKDIR/apple-touch-icon.png"             "$REPO_URL/apple-touch-icon.png"             || err "Failed to download apple-touch-icon.png"
ok "Files downloaded"

# ============================================================ patch
TITLE "Patching"
cp "$WORKDIR/$DASH_SRC" /tmp/dashboard-install.html

# Escape all user values for sed
E_ROUTER_IP=$(escape_sed "$ROUTER_IP")
E_MIHOMO_PORT=$(escape_sed "$MIHOMO_PORT")
E_ADG_PORT=$(escape_sed "$ADG_PORT")
E_WIFI_AP=$(escape_sed "$WIFI_AP")
E_WIFI_AP_PORT=$(escape_sed "$WIFI_AP_PORT")

# Patch DEFAULTS block
sed -i "s|router_ip:\s*'192.168.1.1'|router_ip: '${E_ROUTER_IP}'|g" /tmp/dashboard-install.html

# Patch derived URLs
sed -i "s|'http://192.168.1.1'|'http://${E_ROUTER_IP}'|g" /tmp/dashboard-install.html
sed -i "s|'http://192.168.1.1/ubus'|'http://${E_ROUTER_IP}/ubus'|g" /tmp/dashboard-install.html
sed -i "s|mihomo_api:\s*'http://192.168.1.1:9090'|mihomo_api: 'http://${E_ROUTER_IP}:${E_MIHOMO_PORT}'|g" /tmp/dashboard-install.html
sed -i "s|adguard_host:\s*'192.168.1.1'|adguard_host: '${E_ROUTER_IP}'|g" /tmp/dashboard-install.html

# Mihomo port
sed -i "s|mihomo_port:\s*9090|mihomo_port: ${E_MIHOMO_PORT}|g" /tmp/dashboard-install.html

# AdGuard port (only if enabled)
if [ "$ADG_ENABLE" = "y" ] || [ "$ADG_ENABLE" = "Y" ]; then
  sed -i "s|adguard_port:\s*3003,|adguard_port: ${E_ADG_PORT},|g" /tmp/dashboard-install.html
fi

# WiFi AP
if [ -n "$WIFI_AP" ]; then
  sed -i "s|wifi_ap_ip:\s*'192.168.1.4'|wifi_ap_ip: '${E_WIFI_AP}'|g" /tmp/dashboard-install.html
  sed -i "s|wifi_ap_port:\s*80,|wifi_ap_port: ${E_WIFI_AP_PORT},|g" /tmp/dashboard-install.html
  sed -i "s|wifi_ap_https:\s*false|wifi_ap_https: ${WIFI_AP_HTTPS}|g" /tmp/dashboard-install.html
fi

# Passwords (luci_pass, mihomo_secret, adguard_pass) are NOT patched here.
# The user enters them in the browser modal on first launch (stored in localStorage).

# Patch CLIENT_MAP if user provided entries
if [ -n "$CLIENT_ENTRIES" ]; then
  # Build a JS object string from entries
  JS_MAP="{"
  FIRST=1
  printf '%s' "$CLIENT_ENTRIES" | while IFS=: read -r cip ctype ciface; do
    [ -z "$cip" ] && continue
    if [ "$FIRST" = "1" ]; then
      FIRST=0
    fi
    printf "  '%s': { type: '%s', iface: '%s' },\n" "$cip" "$ctype" "$ciface"
  done > /tmp/_darkboard_clients.js

  if [ -s /tmp/_darkboard_clients.js ]; then
    # Build the replacement block
    REPLACEMENT="const CLIENT_MAP = {\n"
    while IFS= read -r line; do
      REPLACEMENT="${REPLACEMENT}${line}\n"
    done < /tmp/_darkboard_clients.js
    REPLACEMENT="${REPLACEMENT}};"

    # Escape for sed
    E_REPLACEMENT=$(printf '%s' "$REPLACEMENT" | sed ':a;N;$!ba;s/\n/\\n/g;s/[&/]/\\&/g')

    # Replace the entire CLIENT_MAP block
    sed -i "/^const CLIENT_MAP = {/,/^};/c\\${E_REPLACEMENT}" /tmp/dashboard-install.html
    rm -f /tmp/_darkboard_clients.js
    ok "CLIENT_MAP patched with custom entries"
  fi
fi

ok "dashboard.html patched"

# ============================================================ install
TITLE "Installing"
cp /tmp/dashboard-install.html "$DASH_DST"
ok "Installed $DASH_DST"
cp "$WORKDIR/$ACL_SRC" "$ACL_DST"
ok "Installed $ACL_DST"
rm -f /tmp/dashboard-install.html

# ============================================================ PWA files
TITLE "Installing PWA files"

PWA_FILES="manifest.webmanifest sw.js web-app-manifest-192x192.png web-app-manifest-512x512.png favicon.ico favicon.svg favicon-96x96.png apple-touch-icon.png"

for f in $PWA_FILES; do
  cp "$WORKDIR/$f" "/www/$f"
  ok "Installed /www/$f"
done

rm -rf "$WORKDIR"

# ============================================================ restart rpcd
TITLE "Restarting rpcd"
/etc/init.d/rpcd restart 2>/dev/null && ok "rpcd restarted" \
  || info "rpcd restart failed - run: /etc/init.d/rpcd restart"

# ============================================================ done
TITLE "Done"
echo
ok "Installation complete!"
info "Open: http://${ROUTER_IP}/dashboard.html"
echo
