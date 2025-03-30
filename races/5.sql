/*
 Определить, какие классы автомобилей имеют наибольшее количество автомобилей с низкой средней позицией (больше 3.0)
 и вывести информацию о каждом автомобиле из этих классов, включая его имя, класс, среднюю позицию, количество гонок,
 в которых он участвовал, страну производства класса автомобиля, а также общее количество гонок для каждого класса.
 Отсортировать результаты по количеству автомобилей с низкой средней позицией.
 */

-- Запрос для определения классов автомобилей с наибольшим количеством автомобилей с низкой средней позицией
WITH CarAvgPositions AS (
    -- Вычисляем среднюю позицию для каждого автомобиля и количество гонок
    SELECT c.name,
           c.class,
           AVG(r.position) AS avg_position,
           COUNT(r.race)   AS race_count
    FROM Cars c
             JOIN
         Results r ON c.name = r.car
    GROUP BY c.name, c.class),
     PoorPerformanceCars AS (
         -- Фильтруем автомобили с низкой средней позицией (больше 3.0)
         SELECT name,
                class,
                avg_position,
                race_count
         FROM CarAvgPositions
         WHERE avg_position > 3),
     CarsWithPoorPerformance AS (
         -- Подсчитываем количество автомобилей с низкой производительностью в каждом классе
         SELECT class,
                COUNT(*) AS poor_performance_cars_count
         FROM PoorPerformanceCars
         GROUP BY class),
     ClassRaceCounts AS (
         -- Подсчитываем общее количество гонок для каждого класса
         SELECT c.class,
                COUNT(DISTINCT r.race) AS total_races
         FROM Cars c
                  JOIN
              Results r ON c.name = r.car
         GROUP BY c.class)

-- Основной запрос
SELECT ppc.name        AS car_name,
       ppc.class,
       ppc.avg_position,
       ppc.race_count,
       cl.country      AS class_country,
       crc.total_races AS class_total_races
FROM PoorPerformanceCars ppc
         JOIN
     CarsWithPoorPerformance cwpp ON ppc.class = cwpp.class
         JOIN
     Classes cl ON ppc.class = cl.class
         JOIN
     ClassRaceCounts crc ON ppc.class = crc.class
ORDER BY cwpp.poor_performance_cars_count DESC,
         ppc.class,
         ppc.avg_position;
