# Проект базы данных бронирования отелей

## Обзор проекта

Этот проект реализует реляционную базу данных для управления бронированием отелей. Система позволяет отслеживать отели, номера, клиентов и их бронирования. Основная цель - предоставить комплексное решение для управления гостиничными резервациями и обеспечить возможность сложного анализа данных о моделях бронирования и предпочтениях клиентов.

### Цели проекта

- Хранение и управление информацией об отелях, номерах, клиентах и бронированиях
- Обеспечение эффективного управления бронированием с соответствующими связями между сущностями
- Поддержка анализа данных для выявления моделей бронирования и предпочтений клиентов
- Демонстрация возможностей продвинутых SQL-запросов для бизнес-аналитики

## Структура базы данных

База данных состоит из четырех основных таблиц:

### Таблица Hotel (Отель)

Хранит информацию о доступных отелях:
- **ID_hotel**: Первичный ключ, уникальный идентификатор для каждого отеля
- **name**: Название отеля
- **location**: Физическое местоположение отеля

### Таблица Room (Номер)

Содержит детали о номерах в каждом отеле:
- **ID_room**: Первичный ключ, уникальный идентификатор для каждого номера
- **ID_hotel**: Внешний ключ, ссылающийся на таблицу Hotel
- **room_type**: Тип номера (Single, Double или Suite)
- **price**: Стоимость за ночь
- **capacity**: Максимальное количество гостей

### Таблица Customer (Клиент)

Хранит информацию о клиентах:
- **ID_customer**: Первичный ключ, уникальный идентификатор для каждого клиента
- **name**: Полное имя клиента
- **email**: Электронная почта клиента (уникальная)
- **phone**: Контактный номер клиента

### Таблица Booking (Бронирование)

Записывает транзакции бронирования:
- **ID_booking**: Первичный ключ, уникальный идентификатор для каждого бронирования
- **ID_room**: Внешний ключ, ссылающийся на таблицу Room
- **ID_customer**: Внешний ключ, ссылающийся на таблицу Customer
- **check_in_date**: Дата прибытия клиента
- **check_out_date**: Дата отъезда клиента

## Связи между сущностями

- Каждый номер принадлежит к определенному отелю (связь Room и Hotel)
- Каждое бронирование связано с определенным номером (связь Booking и Room)
- Каждое бронирование связано с определенным клиентом (связь Booking и Customer)
- Клиент может иметь несколько бронирований
- Номер может быть забронирован несколько раз (в разные даты)

## Реализованная функциональность

### 1. Анализ множественных бронирований (1.sql)

Определяет клиентов, которые сделали более двух бронирований в разных отелях, и предоставляет подробную информацию об их моделях бронирования:
- Данные клиента (имя, электронная почта, телефон)
- Общее количество бронирований
- Список отелей, где они делали бронирования
- Средняя продолжительность пребывания в днях

```sql
WITH ClientBookings AS (
    -- Get all bookings with hotel information
    SELECT c.ID_customer,
           c.name,
           c.email,
           c.phone,
           b.ID_booking,
           h.ID_hotel,
           h.name                               AS hotel_name,
           b.check_in_date,
           b.check_out_date,
           (b.check_out_date - b.check_in_date) AS stay_duration
    FROM Customer c
             JOIN
         Booking b ON c.ID_customer = b.ID_customer
             JOIN
         Room r ON b.ID_room = r.ID_room
             JOIN
         Hotel h ON r.ID_hotel = h.ID_hotel),
     ClientHotelCount AS (
         -- Count distinct hotels per client
         SELECT ID_customer,
                COUNT(DISTINCT ID_hotel) AS distinct_hotel_count
         FROM ClientBookings
         GROUP BY ID_customer
         HAVING COUNT(DISTINCT ID_hotel) > 1),
     ClientStats AS (
         -- Calculate statistics for clients with bookings in multiple hotels
         SELECT cb.ID_customer,
                cb.name,
                cb.email,
                cb.phone,
                COUNT(cb.ID_booking)                     AS total_bookings,
                AVG(cb.stay_duration)                    AS avg_stay_duration,
                STRING_AGG(DISTINCT cb.hotel_name, ', ') AS booked_hotels
         FROM ClientBookings cb
                  JOIN
              ClientHotelCount chc ON cb.ID_customer = chc.ID_customer
         GROUP BY cb.ID_customer, cb.name, cb.email, cb.phone
         HAVING COUNT(cb.ID_booking) > 2)
-- Final result
SELECT name,
       email,
       phone,
       total_bookings,
       booked_hotels,
       ROUND(avg_stay_duration, 1) AS avg_stay_duration_days
FROM ClientStats
ORDER BY total_bookings DESC;
```

Этот запрос использует Common Table Expressions (CTE) для поэтапного анализа данных:
1. `ClientBookings` - объединяет информацию о клиентах, их бронированиях и отелях
2. `ClientHotelCount` - подсчитывает количество уникальных отелей для каждого клиента
3. `ClientStats` - вычисляет статистику для клиентов с бронированиями в нескольких отелях
4. Финальный запрос форматирует и сортирует результаты

### 2. Анализ высокоценных клиентов (2.sql)

Анализирует клиентов, которые сделали несколько бронирований и потратили значительные суммы:
- Определяет клиентов с более чем двумя бронированиями в разных отелях
- Фильтрует клиентов, которые потратили более $500 на бронирования
- Предоставляет подробную статистику, включая общее количество бронирований, общую потраченную сумму и количество уникальных посещенных отелей
- Результаты сортируются по общей потраченной сумме

```sql
WITH customer_stats AS (SELECT c.ID_customer,
                               c.name,
                               COUNT(DISTINCT b.ID_booking) AS total_bookings,
                               COUNT(DISTINCT r.ID_hotel)   AS unique_hotels,
                               SUM(r.price)                 AS total_spent
                        FROM Customer c
                                 JOIN
                             Booking b ON c.ID_customer = b.ID_customer
                                 JOIN
                             Room r ON b.ID_room = r.ID_room
                        GROUP BY c.ID_customer, c.name),
     multiple_bookings_hotels AS (SELECT ID_customer,
                                         name,
                                         total_bookings,
                                         unique_hotels,
                                         total_spent
                                  FROM customer_stats
                                  WHERE total_bookings > 2
                                    AND unique_hotels > 1),
     high_spenders AS (SELECT ID_customer,
                              name,
                              total_spent,
                              total_bookings
                       FROM customer_stats
                       WHERE total_spent > 500)
SELECT mb.ID_customer,
       mb.name,
       mb.total_bookings,
       mb.total_spent,
       mb.unique_hotels
FROM multiple_bookings_hotels mb
         JOIN
     high_spenders hs ON mb.ID_customer = hs.ID_customer
ORDER BY mb.total_spent;
```

Этот запрос также использует Common Table Expressions (CTE) для поэтапного анализа данных:
1. `customer_stats` - вычисляет статистику для всех клиентов
2. `multiple_bookings_hotels` - фильтрует клиентов с более чем двумя бронированиями в разных отелях
3. `high_spenders` - фильтрует клиентов, которые потратили более $500
4. Финальный запрос объединяет результаты и сортирует их по общей потраченной сумме

### 3. Анализ предпочтений отелей (3.sql)

Категоризирует отели по ценовому диапазону и определяет предпочтения клиентов:
- Категоризирует отели как "Дешевый", "Средний" или "Дорогой" на основе средней цены номера
- Определяет предпочитаемый тип отеля для каждого клиента на основе истории его бронирований
- Перечисляет все отели, посещенные каждым клиентом
- Результаты сортируются по категории предпочтений

```sql
WITH hotel_categories AS (
    -- Calculate average price for each hotel and categorize them
    SELECT 
        h.ID_hotel,
        h.name AS hotel_name,
        AVG(r.price) AS avg_price,
        CASE
            WHEN AVG(r.price) < 175 THEN 'Дешевый'
            WHEN AVG(r.price) >= 175 AND AVG(r.price) <= 300 THEN 'Средний'
            ELSE 'Дорогой'
        END AS hotel_category
    FROM Hotel h
    JOIN Room r ON h.ID_hotel = r.ID_hotel
    GROUP BY h.ID_hotel, h.name
),

customer_hotels AS (
    -- Find all hotels visited by each customer
    SELECT DISTINCT
        c.ID_customer,
        c.name AS customer_name,
        h.ID_hotel,
        hc.hotel_name,
        hc.hotel_category
    FROM Customer c
    JOIN Booking b ON c.ID_customer = b.ID_customer
    JOIN Room r ON b.ID_room = r.ID_room
    JOIN Hotel h ON r.ID_hotel = h.ID_hotel
    JOIN hotel_categories hc ON h.ID_hotel = hc.ID_hotel
),

customer_preferences AS (
    -- Determine each customer's preferred hotel type
    SELECT
        ID_customer,
        customer_name,
        CASE
            WHEN SUM(CASE WHEN hotel_category = 'Дорогой' THEN 1 ELSE 0 END) > 0 THEN 'Дорогой'
            WHEN SUM(CASE WHEN hotel_category = 'Средний' THEN 1 ELSE 0 END) > 0 THEN 'Средний'
            ELSE 'Дешевый'
        END AS preferred_hotel_type,
        STRING_AGG(DISTINCT hotel_name, ', ' ORDER BY hotel_name) AS visited_hotels
    FROM customer_hotels
    GROUP BY ID_customer, customer_name
)

-- Final result with sorting
SELECT
    ID_customer,
    customer_name AS name,
    preferred_hotel_type,
    visited_hotels
FROM customer_preferences
ORDER BY 
    CASE 
        WHEN preferred_hotel_type = 'Дешевый' THEN 1
        WHEN preferred_hotel_type = 'Средний' THEN 2
        WHEN preferred_hotel_type = 'Дорогой' THEN 3
    END;
```

Этот запрос также использует Common Table Expressions (CTE) для поэтапного анализа данных:
1. `hotel_categories` - вычисляет среднюю цену для каждого отеля и категоризирует их
2. `customer_hotels` - находит все отели, посещенные каждым клиентом
3. `customer_preferences` - определяет предпочитаемый тип отеля для каждого клиента
4. Финальный запрос форматирует и сортирует результаты по категории предпочтений

## Инструкции по запуску и тестированию

### Предварительные требования

- Любая система управления базами данных SQL (PostgreSQL, MySQL, SQLite и т.д.)
- SQL-клиент или интерфейс командной строки

### Шаги настройки

1. Создайте новую базу данных (если требуется вашей системой управления базами данных)
2. Запустите скрипт инициализации:
   ```
   psql -d your_database -f booking/init.sql
   ```
   или эквивалентную команду для вашей системы управления базами данных

3. Проверьте, что данные были вставлены правильно:
   ```sql
   SELECT * FROM Hotel;
   SELECT * FROM Room;
   SELECT * FROM Customer;
   SELECT * FROM Booking;
   ```

### Запуск запросов

1. Для запуска запроса о клиентах с несколькими бронированиями в разных отелях:
   ```
   psql -d your_database -f booking/1.sql
   ```

2. Для запуска запроса о высокоценных клиентах с несколькими бронированиями:
   ```
   psql -d your_database -f booking/2.sql
   ```

3. Для запуска запроса о предпочтениях клиентов по категории цен отелей:
   ```
   psql -d your_database -f booking/3.sql
   ```

### Ожидаемые результаты

#### Результаты запроса 1 (Анализ множественных бронирований)

На основе примеров данных запрос должен вернуть клиентов, сделавших более двух бронирований в разных отелях. Для каждого такого клиента будет показана следующая информация:

- **name**: Имя клиента (например, "Jane Smith", "Alice Johnson")
- **email**: Электронная почта клиента
- **phone**: Телефон клиента
- **total_bookings**: Общее количество бронирований (например, 3, 4)
- **booked_hotels**: Список отелей, где клиент делал бронирования (например, "Grand Hotel, Ocean View Resort")
- **avg_stay_duration_days**: Средняя продолжительность пребывания в днях (например, 3.0, 2.5)

Результаты будут отсортированы по количеству бронирований в порядке убывания, так что клиенты с наибольшим количеством бронирований будут отображаться первыми.

#### Результаты запроса 2 (Анализ высокоценных клиентов)

Запрос вернет клиентов, которые сделали более двух бронирований в разных отелях И потратили более $500 на свои бронирования. Для каждого такого клиента будет показана следующая информация:

- **ID_customer**: Идентификатор клиента
- **name**: Имя клиента
- **total_bookings**: Общее количество бронирований
- **total_spent**: Общая сумма, потраченная на бронирования (в долларах)
- **unique_hotels**: Количество уникальных отелей, в которых клиент делал бронирования

Результаты будут отсортированы по общей потраченной сумме в порядке возрастания, так что клиенты, потратившие меньше всего (но все равно более $500), будут отображаться первыми.

#### Результаты запроса 3 (Анализ предпочтений отелей)

Запрос категоризирует клиентов по их ценовым предпочтениям отелей на основе истории бронирований. Для каждого клиента будет показана следующая информация:

- **ID_customer**: Идентификатор клиента
- **name**: Имя клиента
- **preferred_hotel_type**: Предпочитаемый тип отеля ("Дешевый", "Средний" или "Дорогой")
- **visited_hotels**: Список всех отелей, которые клиент посетил

Результаты будут отсортированы по категории предпочтений, так что сначала будут отображаться клиенты с предпочтением "Дешевый", затем "Средний", и в конце - "Дорогой".

### Тестирование

Вы можете протестировать базу данных следующими способами:

1. Добавление новых отелей, номеров, клиентов и бронирований и проверка ограничений
2. Изменение запросов для проверки различных критериев фильтрации и агрегации
3. Создание собственных запросов для анализа моделей бронирования и предпочтений клиентов
