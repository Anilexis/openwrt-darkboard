## Install as an App (PWA)

DarkBoard supports PWA (Progressive Web App) — it can be installed as a standalone app on your device. No app store required. The app works with a Network-First strategy: it always loads fresh data from the router, and falls back to cache only if the router is unreachable.

> **Note on HTTP:** Chrome requires a secure context (HTTPS or localhost) to install PWA and register a Service Worker. Since most home routers serve pages over plain HTTP, you need to whitelist your router's IP in Chrome flags:
> 1. Open `chrome://flags/#unsafely-treat-insecure-origin-as-secure`
> 2. Enter `http://192.168.1.1` (or your router's IP)
> 3. Set to **Enabled** and click **Relaunch**
>
> After this, Chrome will treat your router as a secure origin and allow PWA installation.

### Chrome — Android

1. Open `http://192.168.1.1/dashboard.html` in Chrome
2. Tap the **⋮** menu → **Install app** (or "Add to Home screen")
3. Confirm — the icon appears on your home screen
4. The app opens without browser UI in standalone mode

### Chrome — Windows 11

1. Open `http://192.168.1.1/dashboard.html` in Chrome
2. Click the **install icon** (⊕) in the address bar on the right side, or go to **⋮** menu → **Save and share** → **Install page as app**
3. Click **Install** in the confirmation dialog
4. DarkBoard opens in its own window and is pinned to the taskbar / Start menu

### Safari — iPhone (iOS)

> Safari on iOS does not require the Chrome flags workaround — PWA installation via "Add to Home Screen" works over HTTP on local network addresses.

1. Open `http://192.168.1.1/dashboard.html` in Safari
2. Tap the **Share** button (□↑) at the bottom of the screen
3. Scroll down and tap **Add to Home Screen**
4. Edit the name if desired, tap **Add**
5. The icon appears on your home screen and opens in full-screen mode

## Updates

Because DarkBoard uses a **Network-First** Service Worker strategy, updates are seamless:

- **Dashboard HTML updated on the router** — the app automatically loads the new version on next open, no action needed.
- **Service Worker (`sw.js`) updated** — the new SW is downloaded in the background and activates on the next app restart (close and reopen). Old cache is cleaned up automatically.

---

## Установка как приложение (PWA)

DarkBoard поддерживает PWA (Progressive Web App) — его можно установить как отдельное приложение на устройство. Магазин приложений не нужен. Приложение работает по стратегии Network-First: всегда загружает свежие данные с роутера, и обращается к кэшу только если роутер недоступен.

> **Важно про HTTP:** Chrome требует безопасный контекст (HTTPS или localhost) для установки PWA и работы Service Worker. Так как большинство домашних роутеров работают по обычному HTTP, нужно добавить IP роутера в исключения Chrome:
> 1. Открой `chrome://flags/#unsafely-treat-insecure-origin-as-secure`
> 2. Введи `http://192.168.1.1` (или IP своего роутера)
> 3. Выбери **Enabled** и нажми **Relaunch**
>
> После этого Chrome будет считать этот адрес безопасным и разрешит установку PWA.

### Chrome — Android

1. Открой `http://192.168.1.1/dashboard.html` в Chrome
2. Нажми меню **⋮** → **Установить приложение** (или «Добавить на главный экран»)
3. Подтверди — иконка появится на главном экране
4. Приложение открывается без браузерного интерфейса в standalone-режиме

### Chrome — Windows 11

1. Открой `http://192.168.1.1/dashboard.html` в Chrome
2. Нажми на иконку установки (⊕) справа в адресной строке, либо меню **⋮** → **Сохранить и поделиться** → **Установить страницу как приложение**
3. Нажми **Установить** в диалоге подтверждения
4. DarkBoard откроется в отдельном окне и будет закреплён на панели задач / в меню «Пуск»

### Safari — iPhone (iOS)

> Safari на iOS не требует настройки флагов — установка через «На экран «Домой»» работает по HTTP на локальных адресах.

1. Открой `http://192.168.1.1/dashboard.html` в Safari
2. Нажми кнопку **Поделиться** (□↑) внизу экрана
3. Пролистай вниз и выбери **На экран «Домой»**
4. При желании измени название, нажми **Добавить**
5. Иконка появится на главном экране и будет открываться в полноэкранном режиме

## Обновления

Благодаря стратегии **Network-First** обновления происходят автоматически:

- **Обновился `dashboard.html` на роутере** — приложение автоматически загрузит новую версию при следующем открытии, ничего делать не нужно.
- **Обновился Service Worker (`sw.js`)** — новый SW скачивается в фоне и активируется при следующем перезапуске приложения (закрыть и открыть). Старый кэш удаляется автоматически.
