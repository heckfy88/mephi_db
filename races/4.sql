/*
 Определить, какие автомобили имеют среднюю позицию лучше (меньше) средней позиции всех автомобилей в своем классе
 (то есть автомобилей в классе должно быть минимум два, чтобы выбрать один из них).
 Вывести информацию об этих автомобилях, включая их имя, класс, среднюю позицию, количество гонок,
 в которых они участвовали, и страну производства класса автомобиля.
 Также отсортировать результаты по классу и затем по средней позиции в порядке возрастания.
 */

WITH CarAvgPositions AS (
    -- Вычисляем среднюю позицию для каждого автомобиля
    SELECT c.name,
           c.class,
           AVG(r.position) AS avg_position,
           COUNT(r.race)   AS race_count
    FROM Cars c
             JOIN
         Results r ON c.name = r.car
    GROUP BY c.name, c.class),
     ClassAvgPositions AS (
         -- Вычисляем среднюю позицию для каждого класса и количество автомобилей в классе
         SELECT c.class,
                AVG(r.position)        AS class_avg_position,
                COUNT(DISTINCT c.name) AS car_count
         FROM Cars c
                  JOIN
              Results r ON c.name = r.car
         GROUP BY c.class)

-- Выбираем автомобили с позицией лучше средней в своем классе
SELECT cap.name   AS car_name,
       cap.class,
       cap.avg_position,
       cap.race_count,
       cl.country AS class_country
FROM CarAvgPositions cap
         JOIN
     ClassAvgPositions clap ON cap.class = clap.class
         JOIN
     Classes cl ON cap.class = cl.class
WHERE cap.avg_position < clap.class_avg_position -- Позиция лучше (меньше) средней в классе
  AND clap.car_count >= 2                        -- В классе минимум два автомобиля
ORDER BY cap.class,
         cap.avg_position;