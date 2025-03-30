/*
 Вам необходимо провести анализ данных о бронированиях в отелях и определить предпочтения клиентов по типу отелей.
 Для этого выполните следующие шаги:

Категоризация отелей.
Определите категорию каждого отеля на основе средней стоимости номера:

«Дешевый»: средняя стоимость менее 175 долларов.
«Средний»: средняя стоимость от 175 до 300 долларов.
«Дорогой»: средняя стоимость более 300 долларов.
Анализ предпочтений клиентов.
Для каждого клиента определите предпочитаемый тип отеля на основании условия ниже:

Если у клиента есть хотя бы один «дорогой» отель, присвойте ему категорию «дорогой».
Если у клиента нет «дорогих» отелей, но есть хотя бы один «средний», присвойте ему категорию «средний».
Если у клиента нет «дорогих» и «средних» отелей, но есть «дешевые», присвойте ему категорию предпочитаемых отелей «дешевый».
Вывод информации.
Выведите для каждого клиента следующую информацию:

ID_customer: уникальный идентификатор клиента.
name: имя клиента.
preferred_hotel_type: предпочитаемый тип отеля.
visited_hotels: список уникальных отелей, которые посетил клиент.
Сортировка результатов.
Отсортируйте клиентов так, чтобы сначала шли клиенты с «дешевыми» отелями, затем со «средними» и в конце — с «дорогими».
 */

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