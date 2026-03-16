# DarkBoard - an OpenWRT Dashboard in dark theme

A single-file, real-time monitoring dashboard for OpenWRT routers. No Node.js, no build tools, no backend — just one `dashboard.html` dropped into `/www/`.

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
| **Clients** | DHCP leases with wired/WiFi/TV icons and speed hints |
| **Mihomo Proxy** | All proxy groups (dynamic), selected node, alive/dead counts |
| **AdGuard Home** | Query stats, blocked count, top blocked domains, filtering status |
| **WiFi AP** | External AP reachability and quick-link |
| **Topbar** | Hostname, kernel, firmware, uptime, CPU temp, WAN traffic counter, clock |

**Responsive:** 4-column desktop grid → 2-column tablet → 1–2-column mobile, PWA-ready (add to home screen).
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

---

## Manual Install

```sh
# 1. Edit the CONFIG block at the top of dashboard.html
nano dashboard.html   # edit const C = { ... }

# 2. Copy files
cp dashboard.html /www/dashboard.html
cp dashboard.json /usr/share/rpcd/acl.d/dashboard.json

# 3. Reload rpcd ACL
/etc/init.d/rpcd restart

# 4. Open in browser
# http://192.168.1.1/dashboard.html
```

## Customization

### Add wired clients (for correct icon display)
```js
const WIRED_IPS = new Set(['192.168.1.2', '192.168.1.3']); // your wired client IPs
```

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
| **Clients** | DHCP-клиенты с иконками WiFi/проводных/TV |
| **Mihomo Proxy** | Все proxy-группы динамически, выбранный узел, живые/мёртвые |
| **AdGuard Home** | Статистика запросов, блокировки, топ заблокированных доменов |
| **WiFi AP** | Доступность внешней AP и ссылка на админку |
| **Топбар** | Hostname, ядро, версия прошивки, аптайм, температура, часы |

**Адаптивный:** 4 колонки (десктоп) → 2 колонки (планшет) → 1–2 колонки (телефон). PWA — можно добавить на главный экран.

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
- Данные AdGuard Home
- IP внешней WiFi AP (опционально)

Затем пропатчит `dashboard.html`, скопирует файлы и перезапустит `rpcd`.

---

## Ручная установка

```sh
# 1. Отредактировать блок CONFIG в начале dashboard.html
nano dashboard.html   # отредактировать const C = { ... }

# 2. Скопировать файлы
cp dashboard.html /www/dashboard.html
cp dashboard.json /usr/share/rpcd/acl.d/dashboard.json

# 3. Перезагрузить ACL
/etc/init.d/rpcd restart

# 4. Открыть в браузере
# http://192.168.1.1/dashboard.html
```

---

## Автоопределение оборудования

Дашборд определяет параметры железа самостоятельно при запуске:

- **Количество ядер CPU** — из `/proc/cpuinfo`, fallback через `system.info`
- **Сетевые интерфейсы** — из `network.device` (показываются только существующие)
- **Группы прокси mihomo** — из API mihomo, все группы `Selector`/`URLTest`/`Fallback`
- **Сервисы** — статус только у существующих, неустановленные показывают `N/A`

---

## Настройка проводных клиентов

```js
// Укажи IP проводных клиентов для правильных иконок в CLIENTS
const WIRED_IPS = new Set(['192.168.1.2', '192.168.1.3']);
```

---

## Просмотр логов сервисов

Нажми ☰ рядом с любым сервисом — увидишь последние 25 строк из syslog через `logread -e <имя>`. Нажми ✕ для возврата к списку.

---

## Лицензия

MIT
