DarkNotch — установка / Installation
════════════════════════════════════

1. Перетащите DarkNotch в папку Applications.
   Drag DarkNotch into the Applications folder.

2. Откройте Applications и запустите DarkNotch.
   Open Applications and launch DarkNotch.


ПЕРВЫЙ ЗАПУСК ЗАБЛОКИРОВАН?
FIRST LAUNCH BLOCKED?
────────────────────────────────────
Приложение не подписано платным сертификатом Apple, поэтому macOS
показывает предупреждение. Это нормально. Откройте его одним из способов:

The app has no paid Apple certificate, so macOS warns you. That is
expected. Open it in one of these ways:

Способ 1 — Системные настройки (macOS 15 и новее)
  · Попробуйте открыть приложение и закройте предупреждение.
  · Откройте «Системные настройки» → «Конфиденциальность и безопасность».
  · Прокрутите вниз до раздела «Безопасность».
  · Нажмите «Открыть всё равно» и подтвердите паролем.

Method 1 — System Settings (macOS 15 and later)
  · Try to open the app, then dismiss the warning.
  · Open System Settings → Privacy & Security.
  · Scroll down to the Security section.
  · Click "Open Anyway" and confirm with your password.

Способ 2 — правый клик (macOS 13–14)
  · В Applications нажмите на DarkNotch правой кнопкой (или Control+клик).
  · Выберите «Открыть» → в диалоге снова «Открыть».

Method 2 — right click (macOS 13–14)
  · In Applications, right-click (or Control-click) DarkNotch.
  · Choose Open → Open again in the dialog.

Способ 3 — Терминал (любая версия macOS)
  · Откройте Терминал и выполните две строки:

      xattr -dr com.apple.quarantine /Applications/DarkNotch.app
      open /Applications/DarkNotch.app

Method 3 — Terminal (any macOS version)
  · Open Terminal and run:

      xattr -dr com.apple.quarantine /Applications/DarkNotch.app
      open /Applications/DarkNotch.app


ПОСЛЕ ЗАПУСКА
AFTER LAUNCH
────────────────────────────────────
DarkNotch живёт в строке меню (иконка ◧). Значка в Dock нет — это нормально.

Чтобы работали пункты «Hide App Menus» и «Hide Menu Bar Icons», разрешите
доступ: «Системные настройки» → «Конфиденциальность и безопасность» →
«Универсальный доступ» (Accessibility) → включите DarkNotch.

DarkNotch lives in the menu bar (◧ icon). It has no Dock icon.
For "Hide App Menus" and "Hide Menu Bar Icons", allow Accessibility in
System Settings → Privacy & Security → Accessibility.

Удаление / Uninstall
  · Выберите «Quit DarkNotch» в меню приложения.
  · Удалите /Applications/DarkNotch.app.
  · При желании: rm -rf ~/Library/Application\ Support/DarkNotch
