/*
 Определить, какие клиенты сделали более двух бронирований в разных отелях,
 и вывести информацию о каждом таком клиенте, включая его имя, электронную почту, телефон, общее количество бронирований,
 а также список отелей, в которых они бронировали номера (объединенные в одно поле через запятую с помощью CONCAT).
 Также подсчитать среднюю длительность их пребывания (в днях) по всем бронированиям.
 Отсортировать результаты по количеству бронирований в порядке убывания.
 */

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