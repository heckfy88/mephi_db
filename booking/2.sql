/*
 Необходимо провести анализ клиентов,
 которые сделали более двух бронирований в разных отелях и потратили более 500 долларов на свои бронирования.
 Для этого:

Определить клиентов, которые сделали более двух бронирований и забронировали номера в более чем одном отеле.
 Вывести для каждого такого клиента следующие данные:
 ID_customer,
 имя,
 общее количество бронирований,
 общее количество уникальных отелей, в которых они бронировали номера,
 и общую сумму, потраченную на бронирования.
Также определить клиентов, которые потратили более 500 долларов на бронирования,
 и вывести для них
 ID_customer,
 имя,
 общую сумму,
 потраченную на бронирования,
 и общее количество бронирований.
В результате объединить данные из первых двух пунктов,
 чтобы получить список клиентов, которые соответствуют условиям обоих запросов.
 Отобразить поля:
 ID_customer,
 имя,
 общее количество бронирований,
 общую сумму,
 потраченную на бронирования,
 и общее количество уникальных отелей.
Результаты отсортировать по общей сумме, потраченной клиентами, в порядке возрастания.
 */

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
