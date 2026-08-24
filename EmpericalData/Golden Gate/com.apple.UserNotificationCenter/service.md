# com.apple.UserNotificationCenter

## Basics

- **Process names:** `uncd`
- **Domain:** `system`
- **Plist:** `/System/Library/LaunchDaemons/com.apple.UserNotificationCenter.plist`
- **Binary:** `/System/Library/CoreServices/uncd`
- **Category:** `system_permissions_tcc_cfusernotification`
- **Risk:** `4`
- **Verdict:** `do-not-touch` (всегда держать включенным)

## Notes

### What It Does (За что отвечает):

1. **Менеджмент и регистрация разрешений TCC:**  
   Является системным сервером Mach-порта `com.apple.UNCUserNotification` (`CFUserNotification` subsystem). Это **единственный сервис**, отвечающий за получение, регистрацию и валидацию разрешений TCC в базе данных `TCC.db`.
2. **Добавление приложений в System Settings:**  
   Когда стороннее приложение впервые запрашивает доступ к защищенному ресурсу (микрофон, камера, запись экрана, доступ к диску, автоматизация), `tccd` обращается к `uncd`. Демон регистрирует приложение в базе TCC, после чего оно мгновенно появляется в списке *System Settings > Privacy & Security*, где ему можно выдать доступ тумблером.
3. **Сохранение и валидация уже выданных прав:**  
   Обеспечивает корректную работу ранее выданных разрешений при последующих запусках приложений.

---

### Why It Must NOT Be Disabled (Почему выключать не имеет смысла):

* **Критический функционал:** При отключении `com.apple.UserNotificationCenter` приложения теряют возможность зарегистрироваться в TCC, не появляются в Настройках (показывает «None»), а вызовы API авторизации завершаются тихим отказом.
* **Чистый On-Demand демон (0 MB RAM / 0 процессов в фоне):**  
  В plist отсутствуют флаги `KeepAlive` и `RunAtLoad`. Демон находится в состоянии `state = not running` и не держит резидентный процесс в памяти. `launchd` поднимает `uncd` только на миллисекунды в момент поступления Mach-сообщения, после чего процесс сразу завершается (`exit 0`), освобождая 100% памяти.
* **Экономия от отключения равна нулю:** `+0 MB RAM`, `+0 processes`.

---

### Разделение ролей между `uncd`, `UserNotificationCenterAgent` и `CoreServicesUIAgent`:

1. **`com.apple.UserNotificationCenter` (`system`, `uncd`):**  
   * **Роль:** Регистрация, маршрутизация и менеджмент разрешений в TCC.
   * **Вердикт:** **DO NOT TOUCH / KEEP ENABLED**.
2. **`com.apple.UserNotificationCenterAgent` (`gui/<uid>`, `UserNotificationCenter.app`):**  
   * **Роль:** Исключительно визуальная отрисовка всплывающего модального окна/баннера на экране.
   * **Вердикт:** Может быть отключен в power-user профилях. При отключении окна не спамят на экране, а само разрешение выдаётся через *System Settings > Privacy & Security*.
3. **`com.apple.coreservices.uiagent` (`gui/<uid>`, `CoreServicesUIAgent.app`):**  
   * **Роль:** Безопасность, нотаризация, валидация кода (`com.apple.coreservices.code-evaluation`) и резолвер карантина файлов (`quarantine-resolver`).
   * **Вердикт:** Не трогать для сохранения нормальной верификации софта.

---

## Empirical Test Results

- **Дата:** 2026-08-25  
- **Целевая система:** macOS 27.0 Golden Gate (Build 26A5416b, ARM64)  
- **Методология:** Пошаговое тестирование методом исключения (batch elimination) 16 сервисов групп `notifications-peripheral` и `download-quarantine`.

### Результаты тестов:
1. Отключение всех 14 второстепенных сервисов (`SafariNotificationAgent`, `webpushd`, `usbnotificationagent`, `diagnosticspushd`, `AOSPushRelay`, `MENotificationService`, `noticeboard.agent`, `security.keychain-circle-notification`, `SoftwareUpdateNotificationManager`, `mobile.notification_proxy`, `familynotificationd`, `iCloudNotificationAgent`, `iCloudUserNotificationsd`, `UserNotificationCenterAgent-LoginWindow`) **никак не влияет** на получение и работу разрешений.
2. При отключении `system/com.apple.UserNotificationCenter` получение и работа разрешений **полностью ломается**.
3. При включении `system/com.apple.UserNotificationCenter` (даже при отключенных GUI-агентах) все разрешения выдаются штатно через *System Settings > Privacy & Security*.
4. Замер потребления `uncd` в фоне: **0 KB RSS / 0 KB Footprint** (0 процессов в `ps`).
