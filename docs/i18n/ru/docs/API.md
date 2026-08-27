# Документация API (API Reference)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## Обзор

- API админ-панели работает на `http://localhost:8787`
- API портала жильцов работает на `http://localhost:8788`
- Единый формат ответа: `{"code": 0, "message": "success", "data": {...}}`
- Все ID-поля передаются в кодировке hashids
- Версия API управляется заголовком `API-Version` (по умолчанию `v1`)
- Язык управляется заголовком `Accept-Language` (`zh-CN` / `en-US`, по умолчанию `zh-CN`)

### Онлайн-документация API

После запуска сервиса доступна автоматически сгенерированная интерактивная документация `hg/apidoc`:

| Сторона | Адрес | Число групп |
|----|------|--------|
| Админ-панель | `http://localhost:8787/apidoc` | 10 групп (common/dashboard/system/property-core/property-aux/property-adv/extensions/export/import/upload) |
| Портал жильцов | `http://localhost:8788/apidoc` | 9 групп (публичные/главная/платежи/заявки на ремонт/обратная связь/парковка/мероприятия/личное/расширения) |

---

## API админ-панели (admin :8787)

### Публичные интерфейсы — без аутентификации

#### POST /api/captcha/generate
Получение кликовой капчи.

Параметры запроса: нет

Ответ:
```json
{
  "code": 0,
  "data": {
    "key": "captcha_key_string",
    "image": "base64_encoded_png",
    "extra": { "targets": ["树", "鸟", "花"] }
  }
}
```

#### POST /api/captcha/verify
Проверка кликовой капчи.

Параметры запроса:
| Параметр | Тип | Описание |
|------|------|------|
| key | string | ключ капчи, возвращается generate |
| clicks | array | координаты кликов [{x, y}, ...] |

Ответ:
```json
{
  "code": 0,
  "data": { "valid": true }
}
```

При неудачной проверке `code` равен 422, `data.valid` — `false`.

#### POST /api/auth/login
Вход администратора.

Параметры запроса:
| Параметр | Тип | Описание |
|------|------|------|
| username | string | имя пользователя |
| password | string | пароль |
| captcha_key | string | ключ капчи |
| clicks | array | координаты кликов [{x, y}, ...] |

Ответ:
```json
{
  "code": 0,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "user": { "id": "aB3xK9mW...", "username": "admin", "real_name": "管理员" }
  }
}
```

#### POST /api/auth/refresh
Обновление Token.

Параметры запроса:
| Параметр | Тип | Описание |
|------|------|------|
| refresh_token | string | токен обновления |

Ответ:
```json
{
  "code": 0,
  "data": { "access_token": "eyJ..." }
}
```

#### GET /health
Проверка здоровья.

#### GET /metrics
Метрики Prometheus.

#### GET /api/docs
Документация OpenAPI.

---

### Интерфейсы админ-панели — требуется аутентификация (Bearer Token)

Все интерфейсы имеют префикс `/admin`, требуется заголовок `Authorization: Bearer {access_token}`.

#### Панель приборов

**GET /admin/dashboard**
Получение статистических данных панели приборов.

#### Управление пользователями-администраторами

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/user | список пользователей (?keyword=&status=&page=&page_size=) |
| POST | /admin/user | создание пользователя |
| GET | /admin/user/{hashid} | детали пользователя |
| PUT | /admin/user/{hashid} | обновление пользователя |
| DELETE | /admin/user/{hashid} | удаление пользователя (требуется подтверждение паролем) |
| POST | /admin/user/batch/destroy | пакетное удаление |
| POST | /admin/user/batch/status | пакетное включение/отключение |
| POST | /admin/import/users | импорт пользователей из Excel |

#### Управление ролями и правами

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/role | список ролей |
| POST | /admin/role | создание роли |
| GET | /admin/role/{hashid} | детали роли |
| PUT | /admin/role/{hashid} | обновление роли |
| DELETE | /admin/role/{hashid} | удаление роли |
| GET | /admin/permission | список прав (дерево) |
| POST | /admin/permission | создание права |
| PUT | /admin/permission/{hashid} | обновление права |
| DELETE | /admin/permission/{hashid} | удаление права |

#### Системная конфигурация

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/config | список конфигурации (?group=) |
| POST | /admin/config | создание конфигурации |
| PUT | /admin/config/{hashid} | обновление конфигурации |
| DELETE | /admin/config/{hashid} | удаление конфигурации |

#### Журнал операций

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/log | список журналов (?user_id=&action=&method=&source=&start_date=&end_date=) |

#### Личный кабинет

| Метод | Путь | Описание |
|------|------|------|
| PUT | /admin/profile | изменение личной информации |
| PUT | /admin/profile/password | смена пароля |
| POST | /admin/profile/logout | выход из системы |

#### Экспорт

| Метод | Путь | Описание |
|------|------|------|
| POST | /admin/export/excel | экспорт Excel ({ table, columns, conditions, title }) |
| POST | /admin/export/pdf | экспорт PDF ({ type, title, data }) |

---

### Управление недвижимостью — интерфейсы админ-панели

#### Управление жилым комплексом

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/community | список (?keyword=&status=) |
| POST | /admin/community | создание |
| GET | /admin/community/{hashid} | детали |
| PUT | /admin/community/{hashid} | обновление |
| DELETE | /admin/community/{hashid} | удаление (требуется пароль) |

#### Управление корпусами

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/building | список (?community_id=&keyword=) |
| POST | /admin/building | создание |
| GET | /admin/building/{hashid} | детали |
| PUT | /admin/building/{hashid} | обновление |
| DELETE | /admin/building/{hashid} | удаление |

#### Управление квартирами

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/unit | список (?building_id=) |
| POST | /admin/unit | создание |
| GET | /admin/unit/{hashid} | детали |
| PUT | /admin/unit/{hashid} | обновление |
| DELETE | /admin/unit/{hashid} | удаление |

#### Управление планировками

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/room-type | список |
| POST | /admin/room-type | создание |
| GET | /admin/room-type/{hashid} | детали |
| PUT | /admin/room-type/{hashid} | обновление |
| DELETE | /admin/room-type/{hashid} | удаление |

#### Управление объектами недвижимости

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/room | список (?community_id=&building_id=&unit_id=&status=) |
| POST | /admin/room | создание |
| GET | /admin/room/{hashid} | детали |
| PUT | /admin/room/{hashid} | обновление |
| DELETE | /admin/room/{hashid} | удаление |
| GET | /admin/room/tree | дерево помещений (комплекс→корпус→квартира→помещение) |

#### Управление владельцами

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/owner | список (?keyword=&status=) |
| POST | /admin/owner | создание |
| GET | /admin/owner/{hashid} | детали (включая привязанные объекты) |
| PUT | /admin/owner/{hashid} | обновление |
| DELETE | /admin/owner/{hashid} | удаление (требуется пароль) |
| POST | /admin/owner/batch/import | пакетный импорт из Excel |
| POST | /admin/owner/batch/destroy | пакетное удаление |

#### Управление арендаторами

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/tenant | список (?room_id=&status=) |
| POST | /admin/tenant | создание |
| GET | /admin/tenant/{hashid} | детали |
| PUT | /admin/tenant/{hashid} | обновление |
| DELETE | /admin/tenant/{hashid} | удаление |

#### Типы платежей

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/fee-type | список |
| POST | /admin/fee-type | создание |
| GET | /admin/fee-type/{hashid} | детали |
| PUT | /admin/fee-type/{hashid} | обновление |
| DELETE | /admin/fee-type/{hashid} | удаление |

#### Управление счетами

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/fee-bill | список (?community_id=&status=&due_date_start=&due_date_end=) |
| POST | /admin/fee-bill | создание счёта |
| GET | /admin/fee-bill/{hashid} | детали |
| PUT | /admin/fee-bill/{hashid} | обновление |
| DELETE | /admin/fee-bill/{hashid} | удаление |
| POST | /admin/fee-bill/batch/generate | пакетная генерация счетов |

#### Записи платежей

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/fee-payment | список (?bill_id=&payment_method=&date_start=&date_end=) |
| POST | /admin/fee-payment/offline | регистрация офлайн-приёма |

#### Управление заявками на ремонт

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/repair | список (?status=&category=) |
| POST | /admin/repair | создание |
| GET | /admin/repair/{hashid} | детали (включая записи прогресса) |
| PUT | /admin/repair/{hashid} | обновление |
| DELETE | /admin/repair/{hashid} | удаление |
| PUT | /admin/repair/{id}/assign | назначение исполнителя ({ staff_id }) |
| POST | /admin/repair/{id}/progress | обновление прогресса ({ status_to, remark }) |

#### Управление объявлениями

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/announcement | список (?community_id=&category=&is_published=) |
| POST | /admin/announcement | создание |
| GET | /admin/announcement/{hashid} | детали |
| PUT | /admin/announcement/{hashid} | обновление |
| DELETE | /admin/announcement/{hashid} | удаление |

#### Управление парковкой

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/parking-space | список (?community_id=) |
| POST | /admin/parking-space | создание места |
| PUT | /admin/parking-space/{hashid} | обновление |
| DELETE | /admin/parking-space/{hashid} | удаление |
| GET | /admin/parking-vehicle | список (?owner_id=&space_id=) |
| POST | /admin/parking-vehicle | создание автомобиля |
| PUT | /admin/parking-vehicle/{hashid} | обновление |
| DELETE | /admin/parking-vehicle/{hashid} | удаление |
| GET | /admin/parking-record | записи парковки (?vehicle_id=&date_start=&date_end=) |

#### Управление оборудованием

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/equipment | список (?community_id=&category=&status=) |
| POST | /admin/equipment | создание |
| PUT | /admin/equipment/{hashid} | обновление |
| DELETE | /admin/equipment/{hashid} | удаление |
| GET | /admin/equipment-maintenance | записи обслуживания (?equipment_id=) |
| POST | /admin/equipment-maintenance | создание обслуживания |

#### Обработка жалоб

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/complaint | список (?type=&status=) |
| GET | /admin/complaint/{hashid} | детали |
| PUT | /admin/complaint/{id}/handle | обработка ({ handler_remark }) |
| POST | /admin/complaint/{id}/visit | повторный визит ({ visitor_remark }) |

#### Согласование посетителей

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/visitor | список (?status=) |
| PUT | /admin/visitor/{id}/approve | одобрить визит |

#### Управление договорами

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/contract | список (?contract_type=&status=) |
| POST | /admin/contract | создание |
| PUT | /admin/contract/{hashid} | обновление |
| DELETE | /admin/contract/{hashid} | удаление |

#### Управление финансами

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/finance-income | список доходов (?income_type=&date_start=&date_end=) |
| POST | /admin/finance-income | регистрация дохода |
| GET | /admin/finance-expense | список расходов |
| POST | /admin/finance-expense | регистрация расхода |
| GET | /admin/finance/statistics | статистика доходов/расходов по месяцам (?year=) |

#### Панель недвижимости

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/dashboard/property | статистика недвижимости (к оплате/заселённость/заявки на ремонт/жалобы/тренды доходов и расходов) |
| POST | /admin/export/property-excel | экспорт данных недвижимости в Excel ({ type: owners|bills }) |

#### Охрана и патрулирование

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/security-patrol | список (?community_id=) |
| POST | /admin/security-patrol | создание маршрута |
| GET | /admin/patrol-record | записи (?patrol_id=&staff_id=) |
| POST | /admin/patrol-record | создание записи |

#### Управление уборкой

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/cleaning-area | список зон |
| POST | /admin/cleaning-area | создание зоны |
| GET | /admin/cleaning-record | записи (?area_id=) |
| POST | /admin/cleaning-record | создание записи |

#### Управление озеленением

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/green-area | список зон |
| POST | /admin/green-area | создание зоны |
| GET | /admin/green-maintenance | записи ухода (?area_id=) |
| POST | /admin/green-maintenance | создание записи |

#### Мероприятия сообщества

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/activity | список (?status=) |
| POST | /admin/activity | создание мероприятия |
| PUT | /admin/activity/{hashid} | обновление |
| DELETE | /admin/activity/{hashid} | удаление |
| GET | /admin/activity-signup | список записавшихся (?activity_id=) |
| PUT | /admin/activity-signup/{id}/checkin | отметка о присутствии |

#### Управление энергопотреблением

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/energy-meter | список приборов учёта (?room_id=&meter_type=) |
| POST | /admin/energy-meter | создание прибора |
| GET | /admin/energy-record | записи показаний (?meter_id=&date_start=&date_end=) |
| POST | /admin/energy-record | создание записи |

#### Управление персоналом

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/staff | список (?community_id=&status=) |
| POST | /admin/staff | создание |
| PUT | /admin/staff/{hashid} | обновление |
| DELETE | /admin/staff/{hashid} | удаление |
| POST | /admin/staff/batch/status | пакетное включение/отключение |

#### Уведомления

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/notification-template | список шаблонов |
| POST | /admin/notification-template | создание шаблона |
| PUT | /admin/notification-template/{hashid} | обновление шаблона |
| DELETE | /admin/notification-template/{hashid} | удаление шаблона |
| GET | /admin/notification | список сообщений (?type=&is_read=) |
| POST | /admin/notification/send | ручная отправка уведомления |

#### Рабочие процессы согласования

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/approval-type | список типов согласования |
| POST | /admin/approval-type | создание типа согласования |
| GET | /admin/approval | список согласований (?status=) |
| GET | /admin/approval/{hashid} | детали согласования |
| POST | /admin/approval | подача на согласование |
| PUT | /admin/approval/{hashid}/approve | согласование (одобрить/отклонить) |

#### Управление платежами

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/payment-order | список заказов |
| GET | /admin/payment-order/{hashid} | детали заказа |
| POST | /admin/payment-order/{hashid}/refund | возврат |
| GET | /admin/payment/statistics | статистика платежей |

#### Голосования владельцев

| Метод | Путь | Описание |
|------|------|------|
| GET | /admin/vote | список голосований (?status=) |
| POST | /admin/vote | создание голосования |
| GET | /admin/vote/{hashid}/statistics | статистика подсчёта голосов |
| PUT | /admin/vote/{hashid}/publish | публикация голосования |
| PUT | /admin/vote/{hashid}/end | завершение голосования |

#### SLA · интеллектуальное взыскание · патрулирование · магазин · лица · группа · база знаний

(Полные эндпоинты см. в файле `docs/API.md`)

---

## API портала жильцов (service :8788)

### Публичные интерфейсы — без аутентификации

#### POST /api/captcha/generate
Получение кликовой капчи. (Как в админ-панели)

#### POST /api/captcha/verify
Проверка кликовой капчи. (Запрос/ответ как в админ-панели)

#### POST /api/auth/login
Вход владельца.

Параметры запроса:
| Параметр | Тип | Описание |
|------|------|------|
| phone | string | номер телефона |
| password | string | пароль |
| captcha_key | string | ключ капчи |
| clicks | array | координаты кликов |

Ответ:
```json
{
  "code": 0,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "owner": { "id": "xB9k...", "name": "张三", "phone": "138****1234" }
  }
}
```

#### POST /api/auth/register
Регистрация владельца.

Параметры запроса:
| Параметр | Тип | Описание |
|------|------|------|
| phone | string | номер телефона |
| password | string | пароль (не менее 6 символов) |
| name | string | ФИО |
| captcha_key | string | ключ капчи |
| clicks | array | координаты кликов |
| room_id | string | (опционально) hashid привязываемого помещения |
| id_card_last4 | string | (опционально) последние 4 цифры удостоверения |

#### POST /api/auth/refresh
Обновление Token.

---

### Интерфейсы владельцев — требуется аутентификация (Bearer Token)

Все интерфейсы имеют префикс `/service`, требуется заголовок `Authorization: Bearer {access_token}`.

#### Главная

**GET /service/home**

Ответ:
```json
{
  "code": 0,
  "data": {
    "room_count": 2,
    "pending_amount": "1250.00",
    "pending_bill_count": 3,
    "repairing_count": 1,
    "announcements": [{ "id": "xB9k...", "title": "停水通知", "published_at": "2026-05-20 09:00" }]
  }
}
```

#### Мои объекты недвижимости

| Метод | Путь | Описание |
|------|------|------|
| GET | /service/rooms | список моих объектов |
| GET | /service/room/{hashid} | детали объекта (площадь, ориентация, права собственности, информация о комплексе) |

#### Управление платежами

| Метод | Путь | Описание |
|------|------|------|
| GET | /service/fees/bills | список счетов (?status=0 не оплачен/1 частично оплачен/2 оплачен/3 просрочен) |
| GET | /service/fees/bill/{hashid} | детали счёта (тип платежа, записи оплаты) |
| GET | /service/fees/payments | записи платежей |
| POST | /service/fees/pay | онлайн-оплата ({ bill_id, payment_method, password }) |
| GET | /service/fees/statistics | статистика платежей (?year=2026) |

#### Заявки на ремонт

| Метод | Путь | Описание |
|------|------|------|
| GET | /service/repairs | список заявок (?status=) |
| GET | /service/repair/{hashid} | детали заявки (включая таймлайн прогресса) |
| POST | /service/repair | подача заявки ({ room_id, category, urgency, description, images[], scheduled_at }) |
| DELETE | /service/repair/{hashid} | отмена (требуется пароль, { password }) |
| POST | /service/repair/{hashid}/rate | оценка ({ rating: 1-5, feedback }) |

#### Жалобы и предложения

| Метод | Путь | Описание |
|------|------|------|
| GET | /service/complaints | список жалоб |
| GET | /service/complaint/{hashid} | детали жалобы (включая ход обработки) |
| POST | /service/complaint | подача жалобы ({ type, category, title, content, is_anonymous, images[] }) |
| POST | /service/complaint/{hashid}/satisfaction | оценка удовлетворённости ({ satisfaction: 1-5 }) |

#### Объявления

| Метод | Путь | Описание |
|------|------|------|
| GET | /service/announcements | список объявлений (?category=) |
| GET | /service/announcement/{hashid} | детали объявления |

#### Парковка

| Метод | Путь | Описание |
|------|------|------|
| GET | /service/parking/vehicles | мои автомобили |
| GET | /service/parking/spaces | мои парковочные места |
| GET | /service/parking/records | записи парковки |

#### Посетители

| Метод | Путь | Описание |
|------|------|------|
| GET | /service/visitors | мои заявки на визит |
| POST | /service/visitor | создание заявки (генерация кода пропуска) |
| PUT | /service/visitor/{hashid} | изменение заявки |
| DELETE | /service/visitor/{hashid} | отмена заявки |

#### Мероприятия сообщества

| Метод | Путь | Описание |
|------|------|------|
| GET | /service/activities | список мероприятий (?status=) |
| GET | /service/activity/{hashid} | детали мероприятия |
| POST | /service/activity/{hashid}/signup | запись на участие |
| POST | /service/activity/{hashid}/cancel | отмена записи |

#### Личная информация

| Метод | Путь | Описание |
|------|------|------|
| GET | /service/profile | личная информация |
| PUT | /service/profile | изменение ({ name, email, gender, birthday }) |
| PUT | /service/profile/password | смена пароля ({ old_password, new_password }) |
| POST | /service/profile/logout | выход из системы |

---

## Открытый API — аутентификация по API Key

Входящие внешние интерфейсы только для чтения, предназначены для сторонних систем (интеграция с платформами недвижимости, панели данных и т.д.). Префикс `/open`, все только на чтение.

### Способ аутентификации

Каждый запрос должен содержать заголовок `X-API-Key` со значением Key, сгенерированным `scripts/gen_api_key.php` (64-значный hex, в БД хранится только SHA-256-дайджест):

```bash
curl -H "X-API-Key: <ваш Key>" http://localhost:8788/open/announcements
```

- Отсутствующий или неверный Key возвращает `401` (`{"code":401,"message":"无效的API Key","data":[]}`)
- Управление Key: `php scripts/gen_api_key.php [--name=назначение]` для генерации; отключение/удаление — напрямую в таблице `management_api_key` (`status=0` — отключено, ключ немедленно теряет силу)

### Эндпоинты

#### GET /open/announcements — список объявлений

Параметры: `page` (по умолчанию 1), `category` (опционально). Структура ответа совпадает с `/service/announcements`.

```bash
curl -H "X-API-Key: <ваш Key>" "http://localhost:8788/open/announcements?page=1"
```

#### GET /open/bills — запрос счёта

Параметры: `bill_number` (обязательно, номер счёта). Возвращает детали одного счёта (тип платежа, номер помещения, сумма задолженности). При отсутствии возвращает 404.

```bash
curl -H "X-API-Key: <ваш Key>" "http://localhost:8788/open/bills?bill_number=B202608160001"
```

#### GET /open/repairs — запрос статуса заявки на ремонт

Параметры: `order_number` (обязательно, номер заявки). Возвращает текущий статус и таймлайн прогресса (`progress` — массив). При отсутствии возвращает 404.

```bash
curl -H "X-API-Key: <ваш Key>" "http://localhost:8788/open/repairs?order_number=R202608160001"
```

---

## Коды ошибок

| code | Значение | Описание |
|------|------|------|
| 0 | успех | нормальный ответ |
| 400 | ошибка запроса | неверный формат параметров |
| 401 | не аутентифицирован | Token отсутствует/истёк/недействителен/в чёрном списке |
| 403 | нет прав | роль пользователя не включает требуемое право / аккаунт отключён |
| 404 | не найдено | ресурс не найден |
| 405 | метод не разрешён | HTTP-метод, отличный от GET/POST/PUT/DELETE/OPTIONS |
| 413 | тело запроса слишком велико | превышение 10MB |
| 415 | неподдерживаемый тип содержимого | Content-Type не JSON и не form-urlencoded |
| 422 | ошибка валидации | параметры формы не соответствуют правилам / подтверждение пароля не прошло / неверная капча |
| 429 | слишком много запросов | сработало ограничение частоты / блокировка аккаунта |
| 500 | ошибка сервера | непредвиденное исключение |

## Заголовки ответа ограничения частоты

При срабатывании ограничения возвращается 429, заголовки ответа содержат:

| Заголовок | Описание |
|--------|------|
| X-RateLimit-Limit | лимит количества |
| X-RateLimit-Remaining | оставшееся количество |
| X-RateLimit-Reset | время сброса (Unix-временная метка) |
| Retry-After | рекомендуемые секунды ожидания перед повторной попыткой |
