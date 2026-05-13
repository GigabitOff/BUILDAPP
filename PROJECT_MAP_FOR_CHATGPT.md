# BUILD_TRACKER — PROJECT MAP FOR GPT

Актуальная карта проекта для ИИ-ассистента: структура, модули, методы, API-контракты.

**Дата актуализации:** 2026-05-13
**Источник:** текущее состояние репозитория (`lib/**/*.dart`, `pubspec.yaml`)

---

## 1) Что это за проект

- Пакет: `build_tracker`
- UI-имя приложения: `BUILDAPP` (в `lib/main.dart`)
- Тип: Flutter app (mobile-first; платформенные папки также присутствуют)
- Домен: строительные объекты, задачи, материалы, история, фотоотчёты, уведомления
- Backend: REST API с JWT

---

## 2) Технологический стек

- Dart SDK: `^3.11.0`
- Основные зависимости:
  - `http`
  - `shared_preferences`
  - `image_picker`
  - `share_plus`
- Dev/tools:
  - `flutter_lints`
  - `flutter_launcher_icons`
  - `flutter_native_splash`

---

## 3) Дерево `lib/` (актуальное)

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
    invites_service.dart
    materials_service.dart
    notifications_service.dart
    object_history_service.dart
    objects_service.dart
  screens/
    home_screen.dart
    login_screen.dart
    phone_login_screen.dart
    pin_code_screen.dart
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

## 4) Точка входа и навигационный поток

1. `main()` -> `BuildApp` -> `AppStartScreen`
2. `AppStartScreen.checkToken()`:
   - есть `auth_token` -> `HomeScreen`
   - нет токена -> `PhoneLoginScreen`
3. Phone login:
   - `PhoneLoginScreen._sendCode()` -> `AuthService.startPhoneLogin()`
   - `PinCodeScreen._verifyCode()` -> `AuthService.verifyPhoneCode()`
   - после успеха -> `HomeScreen`
4. `LoginScreen` (email/password) реализован, но не является стандартным стартовым маршрутом
5. `HomeScreen` грузит пользователя из `SharedPreferences` и вызывает `DashboardService.getCounts()`

---

## 5) Конфиг и auth state

- Базовый URL (канон): `ApiConfig.baseUrl = http://185.112.41.227:3036`
- Ключи `SharedPreferences`:
  - `auth_token`
  - `user_name`
  - `user_email`
  - `user_type`
- `AuthService.logout()` очищает все 4 ключа

---

## 6) Полная карта сервисов и методов

### `lib/services/api_config.dart`

- `ApiConfig.baseUrl`

### `lib/services/auth_service.dart` — авторизация и профиль

- `login({email, password})`
- `startPhoneLogin({phone})`
- `verifyPhoneCode({phone, code})`
- `me()`
- `logout()`
- `_saveAuthData(data)` (private)

### `lib/services/dashboard_service.dart` — счётчики главной

- `getCounts()`

### `lib/services/objects_service.dart` — объекты и исполнители

- `_getPrefs()` (private)
- `_getToken()` (private)
- `_getUserType()` (private)
- `getObjects()`
- `createObject(object)`
- `getExecutors()`
- `assignExecutorToObject({objectId, userId, roleOnObject})`

### `lib/services/materials_service.dart` — материалы объекта

- `_getToken()` (private, static)
- `getMaterials(objectId)`
- `createMaterial({objectId, name, unit, quantity, price, comment})`
- `updateMaterial({objectId, materialId, name, unit, quantity, price, comment})`
- `deleteMaterial({objectId, materialId})`

### `lib/services/object_history_service.dart` — история объекта

- `_getToken()` (private, static)
- `getHistory(objectId)`
- `createHistoryItem({objectId, title, description, actionType})`

### `lib/services/notifications_service.dart` — уведомления

- `_getToken()` (private, static)
- `getNotifications({onlyUnread})`
- `getUnreadCount()`
- `markAsRead(notificationId)`
- `markAllAsRead()`

### `lib/services/invites_service.dart` — инвайты в проект

- `createProjectInvite({objectId, roleOnObject})`
- `getInviteInfo(inviteToken)`
- `acceptInvite(inviteToken)`

---

## 7) Карта моделей и фабрик

### `ConstructionObject` (`lib/models/construction_object.dart`)

- Поля: id, name, address, status, customer, responsible, executorName, startDate, endDate, description, tasksCount, photosCount
- Методы:
  - `toJson()`
  - `fromJson(json)` (factory)

### `ObjectMaterial` (`lib/models/object_material.dart`)

- Поля: id, constructionObjectId, name, unit, quantity, price, comment, createdBy, createdAt, updatedAt
- Методы:
  - `fromJson(json)` (factory)

### `ObjectHistoryItem` (`lib/models/object_history_item.dart`)

- Поля: id, constructionObjectId, userId, userName, actionType, title, description, createdAt
- Методы:
  - `fromJson(json)` (factory)

### `ObjectNotification` (`lib/models/object_notification.dart`)

- Поля: id, constructionObjectId, objectName, userId, actorUserId, actorName, title, message, notificationType, isRead, createdAt, readAt
- Методы:
  - `fromJson(json)` (factory)

---

## 8) Карта экранов и ключевых методов

Ниже перечислены основные state-методы и сценарии; UI-вспомогательные `build*` виджеты не расписываются подробно.

### Core screens

- `lib/main.dart`
  - `main()`
  - `BuildApp.build()`
  - `AppStartScreen.initState()`
  - `AppStartScreen.checkToken()`
  - `AppStartScreen.build()`

- `lib/screens/home_screen.dart`
  - `initState()`
  - `loadUser()`
  - `loadDashboardCounts()`
  - `openNotifications()`
  - `logout()`
  - `openPage(page)`
  - `buildCard(...)`

- `lib/screens/phone_login_screen.dart`
  - `_sendCode()`
  - `_showMessage(text)`
  - `dispose()`
  - `build()`
  - `UkrainianPhoneFormatter.formatEditUpdate(...)`

- `lib/screens/pin_code_screen.dart`
  - `_verifyCode()`
  - `_showMessage(text)`
  - `dispose()`
  - `build()`

- `lib/screens/login_screen.dart`
  - `login()`
  - `dispose()`
  - `build()`

### Module screens

- `lib/screens/modules/auth_check_screen.dart`
  - `checkToken()`
  - `build()`

- `lib/screens/modules/notifications_screen.dart`
  - `initState()`
  - `loadNotifications()`
  - `markAsRead(notification)`
  - `markAllAsRead()`
  - `formatDate(raw)`
  - `buildNotificationCard(item)`
  - `buildBody()`
  - `build()`

- `lib/screens/modules/objects_screen.dart`
  - `initScreen()`
  - `loadUserType()`
  - `loadObjects()`
  - `openObject(object)`
  - `addObject()`
  - `dispose()`
  - `build()`

- `lib/screens/modules/object_form_screen.dart`
  - `dispose()`
  - `saveObject()`
  - `field(...)`
  - `build()`

- `lib/screens/modules/object_detail_screen.dart`
  - `loadUserType()`
  - `showAssignExecutorDialog()`
  - `assignExecutor(userId, name)`
  - `shareProjectInvite()`
  - `openObjectTasks()`
  - `openPhotoReports()`
  - `openObjectMaterials()`
  - `openObjectHistory()`
  - `build()`

- `lib/screens/modules/object_tasks_screen.dart`
  - `getToken()`
  - `loadUserType()`
  - `loadTasks()`
  - `createTask(status)`
  - `updateTaskStatus(...)`
  - `deleteTask(taskId)`
  - `formatDate(rawDate)`
  - `showAddTaskSheet()`
  - `showChangeStatusSheet(task)`
  - `openTaskDetails(task)`
  - `buildEmptyState()`
  - `build()`

- `lib/screens/modules/tasks_screen.dart`
  - `getToken()`
  - `loadTasks()`
  - `updateTaskStatus(...)`
  - `formatDate(rawDate)`
  - `safeText(value, fallback)`
  - `resetFilters()`
  - `openFilterSheet()`
  - `showTaskDetails(task)`
  - `buildFilterInfo()`
  - `buildEmptyState()`
  - `buildFilteredEmptyState()`
  - `buildErrorState()`
  - `buildTaskList()`
  - `build()`

- `lib/screens/modules/object_materials_screen.dart`
  - `loadMaterials()`
  - `money(value)`
  - `deleteMaterial(material)`
  - `showMaterialDialog({material})`
  - `buildMaterialCard(material)`
  - `buildBody()`
  - `build()`

- `lib/screens/modules/object_history_screen.dart`
  - `loadHistory()`
  - `actionTitle(type)`
  - `formatDate(value)`
  - `showAddHistoryDialog()`
  - `buildHistoryCard(item)`
  - `buildBody()`
  - `build()`

- `lib/screens/modules/photo_reports_screen.dart`
  - `getToken()`
  - `loadPhotoReports()`
  - `pickImage(source)`
  - `showPhotoSourceSheet()`
  - `showAddPhotoDialog()`
  - `uploadPhotoReport()`
  - `deletePhotoReport(reportId)`
  - `formatDate(rawDate)`
  - `buildEmptyState()`
  - `build()`

---

## 9) API endpoints (как используются в коде)

Префикс: `ApiConfig.baseUrl` (в части файлов есть локальный `baseUrl` с тем же доменом).

- Dashboard:
  - `GET /api/dashboard/counts`
- Auth:
  - `POST /api/auth/login`
  - `POST /api/auth/phone/start`
  - `POST /api/auth/phone/verify`
  - `GET /api/me`
- Notifications:
  - `GET /api/notifications`
  - `GET /api/notifications?unread=1`
  - `GET /api/notifications/unread-count`
  - `POST /api/notifications/{id}/read`
  - `POST /api/notifications/read-all`
- Objects/users:
  - `GET /api/objects` (admin)
  - `GET /api/my-objects` (non-admin)
  - `POST /api/objects`
  - `GET /api/users/executors`
  - `POST /api/construction-objects/{objectId}/users`
- Materials:
  - `GET /api/construction-objects/{objectId}/materials`
  - `POST /api/construction-objects/{objectId}/materials`
  - `PUT /api/construction-objects/{objectId}/materials/{materialId}`
  - `DELETE /api/construction-objects/{objectId}/materials/{materialId}`
- Object history:
  - `GET /api/construction-objects/{objectId}/history`
  - `POST /api/construction-objects/{objectId}/history`
- Tasks:
  - `GET /api/tasks`
  - `GET /api/construction-objects/{objectId}/tasks`
  - `POST /api/construction-objects/{objectId}/tasks`
  - `POST /api/object-tasks/{taskId}/status`
  - `DELETE /api/object-tasks/{taskId}`
- Photo reports:
  - `GET /api/construction-objects/{objectId}/photo-reports`
  - `POST /api/construction-objects/{objectId}/photo-reports` (multipart)
  - `DELETE /api/photo-reports/{reportId}`
- Invites:
  - `POST /api/construction-objects/{objectId}/invite`
  - `GET /api/invites/{inviteToken}`
  - `POST /api/invites/{inviteToken}/accept`

---

## 10) Риски и узкие места

- Дублирование `baseUrl` в отдельных файлах (`objects_service`, `object_tasks_screen`, `photo_reports_screen`)
- Критичность ключа `user_type` для ветки `/api/objects` vs `/api/my-objects`
- Логика auth-ключей в `SharedPreferences` влияет на старт приложения и logout
- Большие “толстые” экраны с HTTP + UI одновременно: `tasks_screen`, `object_tasks_screen`, `photo_reports_screen`, `objects_screen`

---

## 11) Инструкция для GPT при работе с репозиторием

1. Сначала прочитать `PROJECT_CONTEXT.md` и этот файл.
2. Определить экран (`lib/screens/**`) и связанный сервис (`lib/services/**`).
3. Проверить API-контракт в разделе endpoints выше перед изменениями.
4. Не менять ключи `SharedPreferences` и не ломать auth-flow без явного запроса.
5. При изменениях в одном модуле сверять модель (`lib/models/**`) и JSON-поля.
