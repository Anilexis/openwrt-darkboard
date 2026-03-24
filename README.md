# DarkBoard - an OpenWRT Dashboard in dark theme

A single-file, real-time monitoring dashboard for OpenWRT routers. No Node.js, no build tools, no backend — just one `dashboard.html` dropped into `/www/`.

(русский язык ниже)

**🔥 [Click here for Demo](https://Anilexis.github.io/openwrt-darkboard/demo.html) 🔥**
![Dashboard preview](https://raw.githubusercontent.com/Anilexis/openwrt-darkboard/main/preview.png)

## Features

| Panel | What it shows |
|---|---|
| **CPU** | Per-core bars with live % and session-peak max markers |
| **Memory** | RAM / Buffers / Cache / Swap bars with max markers |
| **Storage** | Mount points with used/total, NVMe temperature badge |
| **Services** | Running status of all daemons, ↻ restart & ☰ log viewer per service |
| **Interfaces** | RX/TX rates with traffic-intensity color glow, errors, link speed |
| **Latency** | Ping to cf/google/ya via each mihomo proxy group + DIRECT, with session-max bars |
| **WAN** | IP, gateway, proto, uptime, ISP DNS |
| **Clients** | DHCP leases with wired/WiFi/TV/AP icons based on IP mapping |
| **Mihomo Proxy** | All proxy groups (dynamic), selected node, alive/dead counts |
| **AdGuard Home** | Query stats, blocked count, top blocked domains, filtering status |
| **WiFi AP** | External AP reachability and quick-link |
| **Topbar** | Hostname, kernel, firmware, uptime, CPU temp, WAN traffic counter, clock |

**Responsive:** 4-column desktop grid → 3-column tablet → 2-column mobile.  
**PWA-ready:** install as a native-like app on Android, iOS, and Windows — no app store needed.
[PWA manual](https://Anilexis.github.io/openwrt-darkboard/PWA.md)  
Passwords are stored locally in the browser (LocalStorage). Use the dashboard only on trusted devices!

---

## Requirements

- OpenWRT **23.x / 24.x / 25.x** (tested on 25.12 with apk)
- `rpcd` running (default on all OpenWRT)
- `luci-mod-rpc` or equivalent ubus RPC access
- Optional: `mihomo`/`nikki`, `adguardhome`, `sensors` (lm-sensors), `smartmontools`/`nvme-cli`

---

## Quick Install (on the router)

```sh
wget -qO- https://raw.githubusercontent.com/Anilexis/openwrt-darkboard/main/install.sh | sh
```

The installer will interactively ask for:
- Router IP
- Mihomo API port (default: 9090)
- AdGuard Home port (optional)
- WiFi AP IP (optional)
- Wired client mapping (optional) — see "Client mapping" below

Passwords (LuCI root, Mihomo secret, AdGuard credentials) are **not** asked during install — they are entered in the browser on first launch via a setup modal and stored in localStorage.

---

## Manual Install

```sh
# 1. Download files from GitHub
wget -O dashboard.html https://raw.githubusercontent.com/Anilexis/openwrt-darkboard/main/dashboard.html
wget -O dashboard.json https://raw.githubusercontent.com/Anilexis/openwrt-darkboard/main/dashboard.json

# 2. (Optional) Edit DEFAULTS and CLIENT_MAP at the top of dashboard.html
nano dashboard.html   # edit router_ip in DEFAULTS, and CLIENT_MAP entries

# 3. Copy files to their destinations
cp dashboard.html /www/dashboard.html
cp dashboard.json /usr/share/rpcd/acl.d/dashboard.json

# 4. Reload rpcd ACL
/etc/init.d/rpcd restart

# 5. Open in browser
# http://192.168.1.1/dashboard.html
```

On the first launch, the dashboard will open a setup modal where you enter passwords (LuCI, Mihomo, AdGuard). They are stored only in your browser's localStorage.

## Customization

### Client mapping

The CLIENTS panel uses a static IP-based mapping to determine client type and icon. Edit `CLIENT_MAP` at the top of `dashboard.html`:

```js
const CLIENT_MAP = {
  '192.168.1.2': { type: 'pc', iface: 'eth2' },
  '192.168.1.3': { type: 'pc', iface: 'eth3' },
  '192.168.1.4': { type: 'ap', iface: 'eth4' },
  '192.168.1.5': { type: 'tv', iface: 'eth5' },
};
```

Supported types: `pc`, `tv`, `ap`, `wifi`. Clients not in the map default to WiFi. Hostnames are resolved automatically from DHCP leases.

### Add/remove services from the services panel
```js
const SVC_DAEMON = [
  {name:'nikki',       label:'mihomo/nikki'},
  {name:'adguardhome', label:'AdGuard Home'},
  // ... add your services here
];
```

### Service log viewer
Click ☰ next to any service to see its last 25 syslog lines via `logread -e <name>`. Click ✕ to return to the service list.

---

## License

MIT

---

---

# DarkBoard - OpenWRT Dashboard в тёмной теме

**🔥 [ДЕМО дашборда](https://Anilexis.github.io/openwrt-darkboard/demo.html) 🔥**
![Картинка](https://raw.githubusercontent.com/Anilexis/openwrt-darkboard/main/preview.png)

Дашборд для мониторинга роутера на OpenWRT в реальном времени. Один файл `dashboard.html` — без Node.js, без сборки, без бэкенда.
Пароли хранятся локально в браузере (LocalStorage). Используйте дашборд только на доверенных устройствах!

## Возможности

| Панель | Что показывает |
|---|---|
| **CPU** | Загрузка по ядрам + максимальные отметки за сессию |
| **Memory** | RAM / Buffers / Cache / Swap с барами и пиковыми маркерами |
| **Storage** | Разделы с заполненностью, температура NVMe |
| **Services** | Статус демонов, кнопка ↻ рестарта и ☰ просмотр логов |
| **Interfaces** | RX/TX с цветовой индикацией нагрузки (glow на высокой скорости) |
| **Latency** | Пинги через каждую группу mihomo + DIRECT |
| **WAN** | IP, шлюз, протокол, аптайм, DNS провайдера |
| **Clients** | Клиенты с иконками по IP-маппингу (PC/TV/AP/WiFi) |
| **Mihomo Proxy** | Все proxy-группы динамически, выбранный узел, живые/мёртвые |
| **AdGuard Home** | Статистика запросов, блокировки, топ заблокированных доменов |
| **WiFi AP** | Доступность внешней AP и ссылка на админку |
| **Топбар** | Hostname, ядро, версия прошивки, аптайм, температура, часы |

**Адаптивный:** 4 колонки (десктоп) → 3 колонки (планшет) → 2 колонки (телефон).  
**PWA:** устанавливается как приложение на Android, iOS и Windows — без магазина приложений.
[PWA мануал](https://Anilexis.github.io/openwrt-darkboard/PWA.md)  
Пароли хранятся локально в браузере (LocalStorage). Используйте панель управления только на доверенных устройствах!

---

## Требования

- OpenWRT **23.x / 24.x / 25.x** (протестировано на 25.12 с apk)
- `rpcd` (есть по умолчанию)
- `luci-mod-rpc` или аналог
- Опционально: `mihomo`/`nikki`, `adguardhome`, `lm-sensors`, `smartmontools`

---

## Быстрая установка (на роутере)

```sh
wget -qO- https://raw.githubusercontent.com/Anilexis/openwrt-darkboard/main/install.sh | sh
```

Установщик интерактивно спросит:
- IP роутера
- Порт Mihomo API (по умолчанию: 9090)
- Порт AdGuard Home (опционально)
- IP внешней WiFi AP (опционально)
- Маппинг проводных клиентов (опционально) — см. раздел «Настройка клиентов»

Пароли (LuCI root, секрет Mihomo, данные AdGuard) **не спрашиваются** при установке — они вводятся в браузере при первом запуске через модальное окно настройки и сохраняются в localStorage.

---

## Ручная установка

```sh
# 1. Скачать файлы с GitHub
wget -O dashboard.html https://raw.githubusercontent.com/Anilexis/openwrt-darkboard/main/dashboard.html
wget -O dashboard.json https://raw.githubusercontent.com/Anilexis/openwrt-darkboard/main/dashboard.json

# 2. (Опционально) Отредактировать DEFAULTS и CLIENT_MAP в начале dashboard.html
nano dashboard.html   # изменить router_ip в DEFAULTS и записи CLIENT_MAP

# 3. Скопировать файлы по назначению
cp dashboard.html /www/dashboard.html
cp dashboard.json /usr/share/rpcd/acl.d/dashboard.json

# 4. Перезагрузить ACL
/etc/init.d/rpcd restart

# 5. Открыть в браузере
# http://192.168.1.1/dashboard.html
```

При первом запуске дашборд откроет окно настройки, где нужно ввести пароли (LuCI, Mihomo, AdGuard). Они сохраняются только в localStorage вашего браузера.

---

## Настройка клиентов

Панель CLIENTS использует статический маппинг по IP-адресу для определения типа устройства и иконки. Отредактируйте `CLIENT_MAP` в начале `dashboard.html`:

```js
const CLIENT_MAP = {
  '192.168.1.2': { type: 'pc', iface: 'eth2' },
  '192.168.1.3': { type: 'pc', iface: 'eth3' },
  '192.168.1.4': { type: 'ap', iface: 'eth4' },
  '192.168.1.5': { type: 'tv', iface: 'eth5' },
};
```

Поддерживаемые типы: `pc`, `tv`, `ap`, `wifi`. Клиенты, не указанные в маппинге, отображаются как WiFi. Имена хостов определяются автоматически из DHCP leases.

---

## Просмотр логов сервисов

Нажми ☰ рядом с любым сервисом — увидишь последние 25 строк из syslog через `logread -e <имя>`. Нажми ✕ для возврата к списку.

---

## Лицензия

MIT
