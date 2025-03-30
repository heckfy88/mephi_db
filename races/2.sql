/*
 Определить автомобиль,
 который имеет наименьшую среднюю позицию в гонках среди всех автомобилей,
 и вывести информацию об этом автомобиле, включая его класс, среднюю позицию, количество гонок,
 в которых он участвовал, и страну производства класса автомобиля.
 Если несколько автомобилей имеют одинаковую наименьшую среднюю позицию,
 выбрать один из них по алфавиту (по имени автомобиля).
 */

SELECT c.name          AS car_name,
       c.class,
       cl.country      AS class_country,
       AVG(r.position) AS avg_position,
       COUNT(r.race)   AS race_count
FROM Cars c
         JOIN
     Results r ON c.name = r.car
         JOIN
     Classes cl ON c.class = cl.class
GROUP BY c.name, c.class, cl.country
ORDER BY AVG(r.position), c.name
LIMIT 1;