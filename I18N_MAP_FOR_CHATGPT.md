# BUILD_TRACKER — карта мультиязычности для GPT

Документ для ИИ: как внедрить **русский (ru), украинский (uk), английский (en)** в текущий Flutter-проект без потери контракта с API.

**Дата:** 2026-05-13  
**Связанные файлы контекста:** `PROJECT_MAP_FOR_CHATGPT.md`, `PROJECT_CONTEXT.md` (если есть)

---

## 1) Цель и объём

- Языки: **en**, **ru**, **uk** (коды локали для Flutter: `Locale('en')`, `Locale('ru')`, `Locale('uk')`).
- Переводить: подписи UI, кнопки, подсказки, диалоги, SnackBar, ошибки, показанные пользователю из `Exception(...)`.
- Не трогать без необходимости: URL API, ключи JSON, имена полей `SharedPreferences` (`auth_token`, `user_type`, …).

---

## 2) Рекомендуемый стек (официальный Flutter)

Использовать **генерацию локализаций** (`flutter gen-l10n`), не дублировать строки вручную в коде.

1. В `pubspec.yaml` под `flutter:` добавить:

   ```yaml
   generate: true
   ```

2. Зависимости (часто уже транзитивно от `flutter`):

   - `flutter_localizations` из SDK `flutter`
   - `intl`

3. В корне проекта создать `l10n.yaml`, например:

   ```yaml
   arb-dir: lib/l10n
   template-arb-file: app_en.arb
   output-localization-file: app_localizations.dart
   ```

4. Каталог `lib/l10n/`:

   - `app_en.arb` — **шаблон** (английские строки + описания `@key` для переводчиков)
   - `app_ru.arb` — русские переводы
   - `app_uk.arb` — украинские переводы

5. В `MaterialApp` (`lib/main.dart`):

   - `localizationsDelegates: AppLocalizations.localizationsDelegates` (+ `GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations`, `GlobalCupertinoLocalizations` при необходимости)
   - `supportedLocales: AppLocalizations.supportedLocales`
   - `locale:` — из сохранённого предпочтения пользователя (см. раздел 5)
   - `localeResolutionCallback` или `List<Locale>` fallback: например сначала сохранённый язык, иначе системный, иначе `en`

После правок ARB: `flutter gen-l10n` (или просто `flutter pub get` / сборка — генерация подтянется при `generate: true`).

---

## 3) Именование ключей в ARB

Единый стиль, чтобы GPT не плодил хаос:

- `screen_<screen>_<element>` — тексты экрана  
  Пример: `screen_objects_title`, `screen_objects_search_hint`
- `common_<action>` — общие кнопки: `common_save`, `common_cancel`, `common_retry`
- `error_<domain>_<case>` — сообщения об ошибках для пользователя  
  Пример: `error_auth_no_token`
- `status_object_<slug>` — **отображаемое** имя статуса (см. раздел 4)

Плейсхолдеры в ARB: `"objectDeletedMessage": "Object \"{name}\" will be hidden."` + `@objectDeletedMessage` с `placeholders: { "name": { "type": "String" } }`.

---

## 4) Критично: статусы объекта (API vs UI)

Сейчас в коде статусы строительного объекта заданы и сравниваются как **русские строки** (и, вероятно, так же хранятся/отдаются бэкендом).

Файлы-источники истины по списку статусов:

- `lib/screens/modules/object_form_screen.dart` — поле `status`, список `statuses`
- `lib/screens/modules/objects_screen.dart` — `switch` по `object.status` для цвета/лейбла

Текущие значения **как канон для wire/API** (до согласования смены контракта с бэкендом):

| Каноническое значение (как сейчас в коде/API) | Ключ для ARB (отображение) |
|-----------------------------------------------|----------------------------|
| `Планируется` | `status_object_planned` |
| `В работе` | `status_object_in_progress` |
| `Контроль` | `status_object_control` |
| `На паузе` | `status_object_on_hold` |
| `Завершён` | `status_object_completed` |
| `Проблема` | `status_object_issue` |

**Правило для GPT при рефакторинге:**

1. **Внутренне** по-прежнему хранить/сравнивать/отправлять на API строку **ровно как сейчас** (русская), чтобы не сломать БД и фильтры.
2. **В UI** показывать `AppLocalizations.of(context)!.status_object_*` через маленькую функцию маппинга, например `String displayStatus(BuildContext context, String apiStatus)`.
3. Если позже бэкенд перейдёт на slug (`planned`, `in_progress`, …) — менять только слой маппинга + миграция данных, а не все экраны.

Дополнительно: подписи вроде «Без статуса», «Ответственный: не указан» — отдельные ключи ARB, не смешивать со статусами API.

---

## 5) Выбор языка пользователем

Рекомендуемый минимум:

- Новый ключ `SharedPreferences`: например `app_locale` со значениями `en` | `ru` | `uk` (или пусто = «следовать системе»).
- Экран настроек или пункт в `HomeScreen` (меню) — смена языка + `setState` на корневом виджете или обёртка `MaterialApp` в `StatefulWidget` / простой `ValueNotifier<Locale>` для перестроения при смене.

Для **дат и чисел** использовать `intl` с `Localizations.localeOf(context)` (формат даты не хардкодить строками типа `dd.MM.yyyy` без учёта локали, если важна консистентность).

---

## 6) Карта файлов с пользовательскими строками

Ниже — **где лежит текст**, чтобы GPT знал порядок выноса в ARB. Цифры — приблизительное число строк с кириллицей (по grep), не все строки в файле.

| Файл | Назначение | Заметки для i18n |
|------|------------|------------------|
| `lib/main.dart` | `title: 'BUILDAPP'` | Вынести в ARB или оставить бренд латиницей по желанию |
| `lib/screens/home_screen.dart` | Главное меню, карточки | Много заголовков |
| `lib/screens/phone_login_screen.dart` | Телефон, SMS | Валидация, сообщения |
| `lib/screens/pin_code_screen.dart` | PIN | Сообщения об ошибке |
| `lib/screens/login_screen.dart` | Email login | Редко используемый поток |
| `lib/screens/register_screen.dart` | Регистрация компании | Форма, ошибки |
| `lib/screens/modules/objects_screen.dart` | Список объектов | Статусы, диалоги удаления, поиск |
| `lib/screens/modules/object_form_screen.dart` | Создание/редактирование объекта | Статусы, даты, валидация |
| `lib/screens/modules/object_detail_screen.dart` | Карточка объекта | Длинные тексты, действия |
| `lib/screens/modules/object_tasks_screen.dart` | Задачи по объекту | Очень много строк |
| `lib/screens/modules/tasks_screen.dart` | Общий список задач | Очень много строк |
| `lib/screens/modules/object_materials_screen.dart` | Материалы | Диалоги, суммы |
| `lib/screens/modules/object_history_screen.dart` | История | Типы действий, даты |
| `lib/screens/modules/photo_reports_screen.dart` | Фотоотчёты | Источник фото, ошибки |
| `lib/screens/modules/notifications_screen.dart` | Уведомления | Пустые состояния |
| `lib/screens/modules/auth_check_screen.dart` | Проверка токена | Короткие статусы |
| `lib/screens/modules/users_screen.dart` | Пользователи | Списки, роли |
| `lib/screens/modules/user_form_screen.dart` | Форма пользователя | Поля, ошибки |
| `lib/services/auth_service.dart` | Исключения | Локализовать сообщения **в UI-слое** или оборачивать коды |
| `lib/services/objects_service.dart` | Исключения | То же |
| `lib/services/users_service.dart` | Исключения | То же |
| `lib/services/materials_service.dart` | Исключения | То же |
| `lib/services/object_history_service.dart` | Исключения | То же |
| `lib/services/notifications_service.dart` | Исключения | То же |
| `lib/services/dashboard_service.dart` | Исключения | То же |
| `lib/services/invites_service.dart` | Сообщения в Map | Проверить тексты для пользователя |

**Сервисы:** текст из `throw Exception('...')` лучше не дублировать как «финальный UI-текст». Варианты: код ошибки + маппинг в экране, или централизованный helper `UserFacingError.fromException(e)`.

---

## 7) Порядок работ для GPT (чеклист)

1. Прочитать `PROJECT_MAP_FOR_CHATGPT.md` и этот файл.
2. Включить `generate: true`, добавить `l10n.yaml`, создать `lib/l10n/app_{en,ru,uk}.arb`.
3. Подключить делегаты в `MaterialApp`, задать `supportedLocales`.
4. Реализовать сохранение `app_locale` и смену языка в UI.
5. Вынести строки **по экранам** (сначала auth + home + objects, затем тяжёлые `tasks_*`).
6. Добавить `displayStatus(context, apiStatus)` и не менять значения, уходящие в API, без согласования.
7. Прогнать `flutter analyze` и быстрый ручной прогон трёх локалей.

---

## 8) Стартовый промпт для чата с GPT

```text
Репозиторий: build_tracker (Flutter). Нужна мультиязычность ru / uk / en.
Обязательно прочитай в корне: PROJECT_MAP_FOR_CHATGPT.md и I18N_MAP_FOR_CHATGPT.md.
Используй flutter gen-l10n и ARB в lib/l10n/. Статусы объекта на API пока оставь русскими строками как сейчас; в UI показывай переводы через маппинг из раздела 4 I18N_MAP.
Не меняй эндпоинты API и ключи SharedPreferences без явного запроса.
```

---

## 9) Что не входит в этот документ

- Перевод контента с сервера (названия объектов и т.д.) — только если API начнёт отдавать локализованные поля.
- RTL-языки — не требуются для ru/uk/en.
