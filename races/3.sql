/*
 Определить классы автомобилей,
 которые имеют наименьшую среднюю позицию в гонках,
 и вывести информацию о каждом автомобиле из этих классов, включая его имя, среднюю позицию, количество гонок,
 в которых он участвовал, страну производства класса автомобиля,
 а также общее количество гонок, в которых участвовали автомобили этих классов.
 Если несколько классов имеют одинаковую среднюю позицию, выбрать все из них.
 */

WITH ClassAvgPositions AS (
    -- Вычисляем среднюю позицию для каждого класса автомобилей
    SELECT cl.class,
           cl.country,
           AVG(r.position)        AS avg_position,
           COUNT(DISTINCT r.race) AS total_races
    FROM Classes cl
             JOIN
         Cars c ON cl.class = c.class
             JOIN
         Results r ON c.name = r.car
    GROUP BY cl.class, cl.country),
     MinAvgPosition AS (
         -- Находим минимальную среднюю позицию среди всех классов
         SELECT MIN(avg_position) AS min_avg_position
         FROM ClassAvgPositions)

-- Выбираем информацию о каждом автомобиле из классов с наименьшей средней позицией
SELECT c.name          AS car_name,
       AVG(r.position) AS avg_position,
       COUNT(r.race)   AS race_count,
       cl.country      AS class_country,
       cap.total_races AS class_total_races
FROM Cars c
         JOIN
     Results r ON c.name = r.car
         JOIN
     Classes cl ON c.class = cl.class
         JOIN
     ClassAvgPositions cap ON cl.class = cap.class
         JOIN
     MinAvgPosition map ON cap.avg_position = map.min_avg_position
GROUP BY c.name, cl.country, cap.total_races
ORDER BY AVG(r.position), c.name;