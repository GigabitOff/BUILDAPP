# BUILD_TRACKER — карта проекта (для GPT / ИИ)

Актуальная схема репозитория и контрактов. Использовать вместе с `PROJECT_CONTEXT.md`.

**Дата актуализации карты:** 2026-05-12 (по состоянию кода в репозитории).

---

## 1. Идентификация

| Поле | Значение |
|------|----------|
| Пакет (pubspec) | `build_tracker` |
| Название в UI | **BUILDAPP** (`MaterialApp.title` в `lib/main.dart`) |
| Тип | Flutter-приложение (Android / iOS; в репозитории есть заготовки web / desktop) |
| Предметная область | Контроль строительства: объекты, задачи, материалы, история объекта, фотоотчёты, уведомления |
| Backend | Node.js REST API |
| Авторизация | JWT в `SharedPreferences` после успешного входа; основной сценарий — **телефон + SMS-код** (`PhoneLoginScreen` → `PinCodeScreen`). Запасной экран `login_screen.dart` (email/пароль) в дереве навигации **не подключён**. |

---

## 2. Обязательные правила при правках

- Не ломать существующую бизнес-логику и форматы ответов API.
- Не менять пути эндпоинтов и семантику тел без явного согласия пользователя проекта.
- Осторожно с токеном, `logout`, ролью `user_type` (`admin` влияет на список объектов).
- UI — в духе текущего Material 3 (см. `ThemeData` в `main.dart`).
- Перед крупным рефакторингом — краткий план и список файлов.

---

## 3. Стек (`pubspec.yaml`)

- **SDK:** Dart `^3.11.0`
- **Зависимости:** `flutter`, `cupertino_icons`, `http`, `shared_preferences`, `image_picker`
- **Dev:** `flutter_test`, `flutter_lints`, `flutter_launcher_icons`, `flutter_native_splash`
- **Assets:** `assets/icons/app_icon.png` (иконка и splash по конфигу в `pubspec.yaml`)

---

## 4. Архитектура

Слоёвый монолит без отдельного state-management фреймворка (без BLoC / Provider / Riverpod):

| Слой | Путь | Назначение |
|------|------|------------|
| Точка входа | `lib/main.dart` | `MaterialApp`, тема, `AppStartScreen` — проверка токена |
| UI | `lib/screens/**` | Экраны и сценарии |
| API / локаль | `lib/services/**` | HTTP, заголовки `Authorization`, разбор JSON |
| Модели | `lib/models/**` | Сущности и `fromJson` / `toJson` где есть |

Состояние: в основном `StatefulWidget` + `async` + `setState`.

---

## 5. Дерево `lib/` (все Dart-файлы)

```text
lib/
  main.dart
  models/
    construction_object.dart
    object_history_item.dart
    object_material.dart
    object_notification.dart
  services/
    api_config.dart
    auth_service.dart
    dashboard_service.dart
    materials_service.dart
    notifications_service.dart
    object_history_service.dart
    objects_service.dart
  screens/
    login_screen.dart          ← email/пароль; не используется в стартовом потоке
    phone_login_screen.dart
    pin_code_screen.dart
    home_screen.dart
    modules/
      auth_check_screen.dart
      notifications_screen.dart
      object_detail_screen.dart
      object_form_screen.dart
      object_history_screen.dart
      object_materials_screen.dart
      object_tasks_screen.dart
      objects_screen.dart
      photo_reports_screen.dart
      tasks_screen.dart
```

---

## 6. Поток приложения

1. `main()` → `BuildApp` → `home: AppStartScreen`.
2. `AppStartScreen`: читает `auth_token` из `SharedPreferences`.
3. Токен непустой → `HomeScreen`, иначе → **`PhoneLoginScreen`** (не `LoginScreen`).
4. **Телефон:** `PhoneLoginScreen` → `AuthService.startPhoneLogin` → `PinCodeScreen` → `AuthService.verifyPhoneCode` → сохранение через `_saveAuthData` → `HomeScreen`.
5. **Email/пароль:** реализовано в `LoginScreen` + `AuthService.login`, но из `main` / логаута на этот экран перехода нет — файл остаётся для ручного подключения или отладки.
6. `HomeScreen`: после локальных полей пользователя вызывает **`DashboardService.getCounts()`** для бейджей/цифр на карточках; разделы — уведомления, объекты, задачи, фотоотчёты, проверки (`AuthCheckScreen`).

---

## 7. Сервисы и зона ответственности

| Файл | Роль |
|------|------|
| `api_config.dart` | `ApiConfig.baseUrl` — основной хост API |
| `auth_service.dart` | Логин по паролю, старт/проверка телефона, `me()`, `logout`, сохранение данных в `SharedPreferences` |
| `dashboard_service.dart` | **`GET /api/dashboard/counts`** — агрегированные счётчики для главного экрана (`notifications.new`, `objects.total`, `tasks.total`, `photoReports.total`) |
| `objects_service.dart` | Список объектов (роль admin / не admin), создание объекта, исполнители, привязка пользователя к объекту |
| `materials_service.dart` | CRUD материалов по `objectId` |
| `object_history_service.dart` | Чтение и добавление записей истории объекта |
| `notifications_service.dart` | Список, непрочитанные, отметка прочитанным |

---

## 8. Базовый URL и дублирование

- **Канон:** `lib/services/api_config.dart` → `http://185.112.41.227:3036`
- **Дубли хоста (риск расхождения при смене сервера):**
  - `lib/services/objects_service.dart` — локальная константа `baseUrl` (дублирует хост, не через `ApiConfig`)
  - `lib/screens/modules/object_tasks_screen.dart` — свой `baseUrl`
  - `lib/screens/modules/photo_reports_screen.dart` — свой `baseUrl` (в комментарии — старый IP; фактически совпадает с текущим)

Остальные сервисы и `tasks_screen.dart` используют `ApiConfig.baseUrl`.

---

## 9. Карта API (как в коде)

Префикс: `{ApiConfig.baseUrl}` или эквивалентный дублированный `baseUrl`.

**Дашборд**

- `GET /api/dashboard/counts` — счётчики для `HomeScreen` (`DashboardService`)

**Авторизация и профиль**

- `POST /api/auth/login`
- `POST /api/auth/phone/start`
- `POST /api/auth/phone/verify`
- `GET /api/me`

**Уведомления**

- `GET /api/notifications` (опционально `?unread=1`)
- `GET /api/notifications/unread-count`
- `POST /api/notifications/{notificationId}/read`
- `POST /api/notifications/read-all`

**Объекты и пользователи**

- `GET /api/objects` — если `user_type == 'admin'`
- `GET /api/my-objects` — иначе
- `POST /api/objects` — создание
- `GET /api/users/executors`
- `POST /api/construction-objects/{objectId}/users` — тело: `user_id`, `role_on_object`

**Материалы**

- `GET/POST /api/construction-objects/{objectId}/materials`
- `PUT/DELETE /api/construction-objects/{objectId}/materials/{materialId}`

**История объекта**

- `GET/POST /api/construction-objects/{objectId}/history`

**Задачи**

- `GET /api/tasks`
- `GET/POST /api/construction-objects/{objectId}/tasks`
- запрос к `/api/object-tasks/{taskId}/status` (смена статуса)
- `DELETE /api/object-tasks/{taskId}`

**Фотоотчёты**

- `GET/POST` (multipart) `/api/construction-objects/{objectId}/photo-reports`
- `DELETE /api/photo-reports/{reportId}`

---

## 10. `SharedPreferences`

| Ключ | Назначение |
|------|------------|
| `auth_token` | JWT |
| `user_name` | Имя из `data['user']['name']` |
| `user_email` | Email из `data['user']['email']` (при телефонном входе может быть пустым) |
| `user_type` | Роль из `data['user']['usertype']` (важно для списка объектов) |

`AuthService.logout` удаляет все четыре ключа.

---

## 11. Модели (`lib/models`)

- `ConstructionObject` — объект строительства
- `ObjectMaterial` — материал на объекте
- `ObjectHistoryItem` — запись истории
- `ObjectNotification` — уведомление

---

## 12. Остальной репозиторий (кратко)

- `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` — платформенные проекты Flutter
- `assets/icons/` — иконка приложения
- `analysis_options.yaml` — анализатор / линты
- `pubspec.lock` — зафиксированные версии пакетов

В каталоге `test/` нет пользовательских Dart-тестов (или он пуст относительно сценариев приложения).

---

## 13. Рискованные зоны

- Авторизация, сохранение и очистка токена
- Разделение admin / не admin для `GET` объектов
- `HomeScreen` + `DashboardService` — при ошибке счётчики обнуляются молча (`catch` без сообщения пользователю)
- `object_tasks_screen.dart`, `tasks_screen.dart`, `photo_reports_screen.dart`, `objects_screen.dart` — много UI и запросов
- Согласованность `baseUrl` между файлами

---

## 14. Порядок работы для ИИ

1. Прочитать `PROJECT_CONTEXT.md` и этот файл.
2. Найти экран в `lib/screens/...` и связанный `service` / `model`.
3. Сохранить контракт API и ключи `SharedPreferences`.
4. Сохранить стиль UI.
5. По возможности прогнать `flutter analyze`.

---

## 15. Стартовый промпт для другой сессии

```text
Ты работаешь с репозиторием BUILD_TRACKER (Flutter, бренд BUILDAPP).
Правила: не ломай бизнес-логику; не меняй API без подтверждения; осторожно с JWT и user_type (admin).
Контекст: PROJECT_CONTEXT.md и PROJECT_MAP_FOR_CHATGPT.md в корне проекта.
Старт без токена: PhoneLoginScreen → PinCodeScreen; LoginScreen (email) в навигации не задействован.
Перед изменениями кратко опиши план и список файлов.
```
