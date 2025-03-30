/*
 Определить, какие автомобили из каждого класса имеют наименьшую среднюю позицию в гонках,
 и вывести информацию о каждом таком автомобиле для данного класса, включая его класс,
 среднюю позицию и количество гонок, в которых он участвовал.
 Также отсортировать результаты по средней позиции.
 */


WITH AveragePositions AS (
    -- Вычисляем среднюю позицию и количество гонок для каждого автомобиля
    SELECT c.name          AS car_name,
           c.class,
           AVG(r.position) AS avg_position,
           COUNT(r.race)   AS race_count
    FROM Cars c
             JOIN
         Results r ON c.name = r.car
    GROUP BY c.name, c.class),
     RankedCars AS (
         -- Ранжируем автомобили в каждом классе по средней позиции
         SELECT car_name,
                class,
                avg_position,
                race_count,
                RANK() OVER (PARTITION BY class ORDER BY avg_position) AS position_rank
         FROM AveragePositions)
-- Выбираем автомобили с наименьшей средней позицией в каждом классе
SELECT class,
       car_name,
       avg_position,
       race_count
FROM RankedCars
WHERE position_rank = 1
ORDER BY avg_position;