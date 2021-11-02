#66 MSSQL
# Для всех дней в интервале с 01/04/2003 по 07/04/2003 
# определить число рейсов из Rostov.
# Вывод: дата, количество рейсов

SELECT date as dt, MAX(Qty) as Qty FROM (
    SELECT date, COUNT(*) Qty FROM (
        SELECT DISTINCT date, t.trip_no  FROM Pass_in_trip pit 
        FULL JOIN Trip t ON t.trip_no=pit.trip_no 
        WHERE date BETWEEN '2003-04-01' AND '2003-04-07' AND t.town_from='Rostov'
    ) AS t
    GROUP BY date
    UNION SELECT '2003-04-01', 0
    UNION ALL
    SELECT '2003-04-02', 0
    UNION ALL
    SELECT '2003-04-03', 0
    UNION ALL
    SELECT '2003-04-04', 0
    UNION ALL
    SELECT '2003-04-05', 0
    UNION ALL
    SELECT '2003-04-06', 0
    UNION ALL
    SELECT '2003-04-07', 0
) AS t
GROUP BY date

#65 MSSQL
# Пронумеровать уникальные пары {maker, type} из Product, 
# упорядочив их следующим образом:
# - имя производителя (maker) по возрастанию;
# - тип продукта (type) в порядке PC, Laptop, Printer.
# Если некий производитель выпускает несколько типов продукции, 
# то выводить его имя только в первой строке;
# остальные строки для ЭТОГО производителя должны содержать 
# пустую строку символов (''). 

SELECT 
    row_number() over(ORDER BY maker, ord) as num,
    maker_new,
    type
FROM (
    SELECT 
        maker,
        type, 
        CASE 
            WHEN type = 'PC'
            THEN 1
            WHEN type = 'Laptop'
            THEN 2
            ELSE 3
        END as ord,
        CASE
            WHEN type='PC'
            THEN maker
            WHEN (type='Laptop' AND maker IN (SELECT maker FROM Product WHERE type='PC')) 
                OR 
                 (type='Printer' AND maker IN (SELECT maker FROM Product WHERE type='PC'))
            THEN ''
            WHEN (type='Laptop' AND maker NOT IN (SELECT maker FROM Product WHERE type='PC'))
            THEN maker
            WHEN (type='Printer' AND maker IN (SELECT maker FROM Product WHERE type='PC'))
                OR 
                (type='Printer' AND maker IN (SELECT maker FROM Product WHERE type='Laptop'))
            THEN ''
            ELSE maker
        END as maker_new
    FROM Product p 
    GROUP BY type, maker 
) as t
ORDER BY maker

#64 MSSQL
-- Using the Income and Outcome tables, determine for 
-- each buy-back center the days when it received funds 
-- but made no payments, and vice versa. 
-- Result set: point, date, type of 
-- operation (inc/out), sum of money per day

SELECT i2.point, i2.date, 'inc' AS operation, SUM(inc) as money_sum FROM Income i2, (
    SELECT point, date FROM Income i1
    EXCEPT 
    SELECT i.point, i.date FROM Income i  
    INNER JOIN Outcome o ON i.point = o.point AND i.date = o.date
    ) as t
WHERE i2.point = t.point AND i2.date = t.date
GROUP BY i2.point, i2.date
UNION 
SELECT o3.point, o3.date, 'out', SUM(out) FROM Outcome o3, (
    SELECT o2.point, o2.date FROM Outcome o2 
    EXCEPT
    SELECT o1.point, o1.date FROM Outcome o1
    INNER JOIN Income i3 ON i3.point = o1.point AND i3.date = o1.date 
) AS t1
WHERE t1.point = o3.point AND t1.date = o3.date
GROUP BY o3.point, o3.date
---

SELECT i2.point, i2.date, 'inc' as operation, SUM(i2.inc) as money_sum FROM Income i2
JOIN (
    SELECT point, date FROM Income
    EXCEPT
    SELECT i.point, i.date FROM Income i 
    INNER JOIN Outcome o ON i.point = o.point  AND i.date = o.date
) AS t1 ON t1.point = i2.point AND t1.date = i2.date    
GROUP BY i2.point, i2.date
UNION
SELECT o3.point, o3.date, 'out', SUM(o3.out) FROM Outcome o3 
JOIN (
    SELECT point, date FROM Outcome o2 
    EXCEPT
    SELECT i3.point, i3.date FROM Income i3 
    INNER JOIN Outcome o1 ON i3.point = o1.point  AND i3.date = o1.date
) AS t2 ON t2.point = o3.point AND t2.date = o3.date    
GROUP BY o3.point, o3.date

#63 MSSQL
-- Find the names of different passengers that ever travelled more 
-- than once occupying seats with the same number. 

SELECT name FROM Passenger
WHERE ID_psg In (
    SELECT ID_psg FROM  Pass_in_trip pit
    GROUP BY ID_psg, place
    HAVING COUNT(*) > 1
)



# 62 MSSQL 
-- For the database with money transactions being recorded not more 
-- than once a day, calculate the total cash balance of 
-- all buy-back centers at the beginning of 04/15/2001.

SELECT
    SUM(
        CASE 
            WHEN sum_inc IS NULL
            THEN 0
            ELSE sum_inc
        END
        -
        CASE 
            WHEN sum_out IS NULL
            THEN 0
            ELSE sum_out
        END
    ) AS Remain
FROM (
    SELECT t1.point, t1.sum_inc, t2.sum_out FROM (
        SELECT point, SUM(inc) AS sum_inc FROM Income_o
        WHERE date < '2001-04-15'
        GROUP BY point
    ) AS t1 
    FULL JOIN (
        SELECT point, SUM(out) AS sum_out FROM Outcome_o
        WHERE date < '2001-04-15'
        GROUP BY point
    ) AS t2 ON t1.point = t2.point  
) AS t3 

# 61 MSSQL
-- For the database with money transactions being recorded not more 
-- than once a day, calculate the total cash balance of 
-- all buy-back centers. 

SELECT  
    SUM(
        CASE 
            WHEN sum_inc is NULL
            THEN 0
            ELSE sum_inc 
        END 
        - 
                CASE 
            WHEN sum_out is NULL
            THEN 0
            ELSE sum_out 
        END) AS Remain  
FROM (
    SELECT t1.point, t1.sum_inc, t2.sum_out FROM ( 
        SELECT point, SUM(inc) AS sum_inc FROM Income_o
        GROUP BY point 
    ) AS t1
    FULL JOIN (
        SELECT point, SUM(out) AS sum_out FROM Outcome_o
        GROUP BY point
    ) AS t2 ON t1.point = t2.point
) AS t3


# 60 MSSQL
-- For the database with money transactions being recorded not more 
-- than once a day, calculate the cash balance of each 
-- buy-back center at the beginning of 4/15/2001. Note: exclude centers 
-- not having any records before the specified date. Result set: 
-- point, balance 

SELECT 
    point,
    (CASE 
        WHEN sum_inc IS NULL
        THEN 0
        ELSE sum_inc
    END 
    -
    CASE 
        WHEN sum_out IS NULL
        THEN 0
        ELSE sum_out
    END ) AS Remain 
FROM (
    SELECT t1.point, t1.sum_inc, t2.sum_out FROM (
        SELECT point, SUM(inc) as sum_inc FROM Income_o
        WHERE date < '2001-04-15'
        GROUP BY point 
    ) AS t1 
    FULL JOIN (
        SELECT point, SUM(out) as sum_out FROM Outcome_o
        WHERE date < '2001-04-15'
        GROUP BY point
    ) AS t2 ON t1.point = t2.point
) AS t3
--

SELECT 
    point, 
    IIF(sum_inc IS NULL, 0, sum_inc)
    -
    IIF(sum_inc IS NULL, 0, sum_out)
    FROM (
    SELECT t1.point, sum_inc, sum_out FROM (
        SELECT point, SUM(inc) as sum_inc FROM Income_o 
        WHERE date < '2001-04-15'
        GROUP BY point
    ) AS t1 
    FULL JOIN (
        SELECT point, SUM(out) as sum_out FROM Outcome_o 
        WHERE date < '2001-04-15'
        GROUP BY point
    ) AS t2 ON t1.point = t2.point
) AS t3



-- 25.01.21 MySQL
# 59 
-- Calculate the cash balance of each buy-back center for the 
-- database with money transactions being recorded not more than once 
-- a day. Result set: point, balance. 

SELECT 
    point, 
    CASE 
        WHEN _inc IS NULL
        THEN 0
        ELSE _inc 
    END
    -
    CASE
        WHEN _out IS NULL
        THEN 0
        ELSE _out
    END AS Remain
FROM (  
    SELECT  
        t1.point, _inc, _out
    FROM (
        SELECT point, SUM(inc) AS _inc 
        FROM Income_o io 
        GROUP BY point 
    ) AS t1 
    LEFT JOIN (
        SELECT point, SUM(oo.out) AS _out 
        FROM Outcome_o oo 
        GROUP BY point
    ) AS t2
    ON t1.point = t2.point
    UNION
    SELECT  
        t1.point, _inc, _out
    FROM (
        SELECT point, SUM(inc) AS _inc 
        FROM Income_o io 
        GROUP BY point 
    ) AS t1 
    RIGHT JOIN (
        SELECT point, SUM(oo.out) AS _out 
        FROM Outcome_o oo 
        GROUP BY point
    ) AS t2
    ON t1.point = t2.point
) as t
-- 24.01.21
# 58 
-- For each product type and maker in the Product table, 
-- find out, with a precision of two decimal places, the 
-- percentage ratio of the number of models of the actual 
-- type produced by the actual maker to the total number 
-- of models by this maker. Result set: maker, product type, 
-- the percentage ratio mentioned above. 

# 57
-- For classes having irreparable combat losses and at least three 
-- ships in the database, display the name of the class 
-- and the number of ships sunk.

SELECT
    class,
    COUNT(*) AS sunkn
FROM (
    SELECT c.class, s.name, o2.result FROM Classes c 
    JOIN Ships s ON s.class = c.class
    JOIN Outcomes o2 ON o2.ship = s.name 
    UNION
    SELECT c.class, o.ship, o.result FROM Classes c 
    JOIN Outcomes o ON o.ship = c.class
) AS t 
WHERE result = 'sunk'
    AND class IN (
        SELECT 
            class
        FROM (
            SELECT c.class, s.name FROM Classes c 
            JOIN Ships s ON s.class = c.class
            UNION
            SELECT c.class, o.ship FROM Classes c 
            JOIN Outcomes o ON o.ship = c.class
        ) AS t  
        GROUP BY class
        HAVING COUNT(name) >= 3
)
GROUP BY class
    

# 56
-- For each class, find out the number of ships of 
-- this class that were sunk in battles. Result set: class, 
-- number of ships sunk. 
-- >>> 

SELECT 
    class, 
    SUM(sunks) as sunks 
FROM (
    SELECT 
        class, 
        CASE 
            WHEN result = 'sunk' 
                THEN 1 
                ELSE 0
        END AS sunks
    FROM ( 
        SELECT c.class, o.ship, o.result FROM Classes c 
        LEFT JOIN Ships s ON s.class = c.class 
        JOIN Outcomes o ON  s.name = o.ship 
        UNION 
        SELECT c.class, o.ship, o.result FROM Classes c 
        LEFT JOIN Outcomes o ON  c.class = o.ship
    ) AS t
) AS t2 
GROUP BY class

SELECT 
    class, 
    SUM(IF (result = 'sunk', True, False))
FROM ( 
    SELECT c.class, o.ship, o.result FROM Classes c 
    LEFT JOIN Ships s ON s.class = c.class 
    JOIN Outcomes o ON  s.name = o.ship 
    UNION 
    SELECT c.class, o.ship, o.result FROM Classes c 
    LEFT JOIN Outcomes o ON  c.class = o.ship
) AS t
GROUP BY class 


-- 23.01.21
# 55
-- For each class, determine the year the first ship of 
-- this class was launched. If the lead ship’s year of 
-- launch is not known, get the minimum year of launch 
-- for the ships of this class. Result set: class, year. 

SELECT  
    class,
    MIN(launched)
FROM (
    SELECT * FROM Ships 
    UNION
    SELECT o.ship, c.class, NULL FROM Classes c 
    LEFT JOIN Outcomes o ON o.ship = c.class
) AS t
GROUP BY class

# 54
-- With a precision of two decimal places, determine the average 
-- number of guns for all battleships (including the ones in 
-- the Outcomes table). 

SELECT 
    CAST(AVG(numGuns*1.0) AS DECIMAL(6, 2)) AS Avg_numG
FROM (
    SELECT s.name, c.numGuns, c.type FROM Classes c 
    JOIN Ships s ON s.class = c.class 
    UNION
    SELECT o.ship, c.numGuns, c.type FROM Classes c 
    JOIN Outcomes o ON o.ship = c.class 
) AS t
WHERE type = 'bb'

# 53
-- With a precision of two decimal places, determine the average 
-- number of guns for the battleship classes. 

SELECT 
  CAST(AVG(numGuns*1.0) AS DECIMAL(6, 2)) 
    as avg_numGuns FROM Classes c 
WHERE type = 'bb'

# 52 !!
-- Determine the names of all ships in the Ships table 
-- that can be a Japasenese battleship having at least nine 
-- main guns with a caliber of less than 19 inches 
-- and a displacement of not more than 65 000 tons. 
SELECT name FROM (
    SELECT 
        s.name, 
        c.country,
        c.type,
        c.numGuns, 
        c.bore, 
        c.displacement 
    FROM Classes c
    JOIN Ships s ON s.class = c.class
    UNION 
    SELECT
        o.ship, 
        c.country, 
        c.type,
        c.numGuns, 
        c.bore, 
        c.displacement  
    FROM Classes c
    JOIN Outcomes o ON o.ship = c.class
) AS t
WHERE (country = 'Japan' OR country IS NULL)
    AND (numGuns >= 9 OR numGuns IS NULL)
    AND (type = 'bb' OR type IS NULL)
    AND (bore < 19 OR bore IS NULL)
    AND (displacement <= 65000 OR displacement IS NULL)


# 51  !!!!!!!!!!!!!!!!!!!
-- Find the names of the ships with the largest number 
-- of guns among all ships having the same displacement (including 
-- ships in the Outcomes table). 
SELECT s.name FROM Classes as c
JOIN Ships as s ON s.class = c.class
WHERE numGuns = (
    SELECT MAX(c.numGuns) FROM Classes c2 
    WHERE c2.displacement = c.displacement 
)
UNION 
SELECT o.ship FROM Classes as c
JOIN Outcomes o ON o.ship = c.class
WHERE numGuns = (
    SELECT MAX(c.numGuns) FROM Classes c2 
    WHERE c2.displacement = c.displacement 
) 

# 50 
-- Find the battles in which Kongo-class ships from the Ships 
-- table were engaged.

SELECT DISTINCT(battle) FROM (
    SELECT s.name, s.class, o.battle FROM Outcomes o 
    JOIN Ships s ON s.name = o.ship 
    JOIN Classes c ON c.class = s.class 
    UNION 
    SELECT o.ship, c.class, o.battle FROM Outcomes o 
    JOIN Classes c ON c.class = o.ship
) AS t
WHERE class = 'Kongo'

# 49 
-- Find the names of the ships having a gun caliber 
-- of 16 inches (including ships in the Outcomes table). 

SELECT name FROM ( 
    SELECT s.name, c.class, c.bore  FROM Classes c 
    JOIN Ships s ON s.class = c.class 
    UNION
    SELECT o.ship, c.class, c.bore FROM Classes c 
    JOIN Outcomes o ON o.ship = c.class 
) AS t
WHERE bore = 16

# 48 
-- Find the ship classes having at least 
-- one ship sunk in battles.

SELECT class FROM ( 
    SELECT c.class, o.result  FROM Classes c 
    JOIN Ships s ON s.class = c.class 
    JOIN Outcomes o ON s.name = o.ship
    UNION
    SELECT c.class, o.result FROM Classes c 
    JOIN Outcomes o ON o.ship = c.class 
) AS t
WHERE t.result = 'sunk'

# 47 !!!
-- Find the countries that have lost all their ships in 
-- battles 

WITH boat_count AS (
    SELECT country, COUNT(*) as 'launched' FROM (
        SELECT c.country, c.class, s.name FROM Ships s 
        JOIN Classes c On s.class = c.class
        UNION 
        SELECT c.country, c.class, o.ship FROM Outcomes o 
        JOIN Classes c On o.ship = c.class
    ) as t 
    GROUP BY country
)
SELECT boat_count.country FROM (
    SELECT country, COUNT(*) as 'sunk' FROM (   
        SELECT s.name, c.class, c.country, o.result FROM Outcomes o
        JOIN Ships s ON s.name = o.ship
        JOIN Classes c ON c.class = s.class
        UNION
        SELECT o.ship, c.class, c.country, o.result FROM Outcomes o
        JOIN Classes c ON c.class = o.ship
    ) AS t1 
    WHERE result = 'sunk'
GROUP BY country
) AS sunk_count
JOIN boat_count ON boat_count.country = sunk_count.country
WHERE boat_count.launched = sunk_count.sunk


    SELECT country, COUNT(*) as launched FROM (
        SELECT c.country, c.class, s.name FROM Ships s 
        JOIN Classes c On s.class = c.class
        UNION 
        SELECT c.country, c.class, o.ship FROM Outcomes o 
        JOIN Classes c On o.ship = c.class
    ) as t 
    GROUP BY country

-- 22.01.21
# 46
-- For each ship that participated in the Battle of Guadalcanal, 
-- get its name, displacement, and the number of guns.

SELECT o.ship, cl.displacement, cl.numGuns FROM Ships s
RIGHT JOIN Outcomes o ON s.name = o.ship
LEFT JOIN Classes as cl ON cl.class = s.class OR cl.class = o.ship
WHERE o.battle = 'Guadalcanal'

# 45 !!
-- Find all ship names consisting of three or more words 
-- (e.g., King George V). Consider the words in ship names 
-- to be separated by single spaces, and the ship names 
-- to have no leading or trailing spaces 

SELECT * FROM ( 
    SELECT name FROM Ships
    UNION
    SELECT ship FROM Outcomes
) as t
WHERE name LIKE '% % %'

SELECT IF (name IS NOT NULL, name, ship) as ship FROM (
    (SELECT * FROM Ships s
    LEFT JOIN Outcomes o ON s.name = o.ship)
    UNION 
    (SELECT * FROM Ships s
    RIGHT JOIN Outcomes o ON s.name = o.ship)
) AS t
WHERE ship LIKE '% % %'

# 43 !!
-- Get the battles that occurred in years 
-- when no ships were launched into water.
SELECT DISTINCT(name) FROM Battles
WHERE YEAR(date) NOT IN (SELECT launched FROM Ships WHERE launched IS NOT NULL);

# 41 
-- For each maker who has models at least in 
-- one of the tables PC, Laptop, or Printer, 
-- determine the maximum price for his products.
-- Output: maker; if there are NULL values among the prices 
-- for the products of a given maker, display NULL for this maker, 
-- otherwise, the maximum price.

# 40 !!
-- Get the makers who produce only one product 
-- type and more than one model. Output: maker, type.

SELECT maker, MAX(type) FROM Product
GROUP BY maker
HAVING COUNT(DISTINCT type) = 1 AND COUNT(model) > 1

# 39 !!

-- Find the ships that `survived for future battles`; 
-- that is, after being damaged in a battle, they participated 
-- in another one, which occurred later.

SELECT DISTINCT(t1.ship) FROM (
    SELECT ship, battle, result, date FROM Outcomes as o
    JOIN Battles as b ON o.battle = b.name 
    WHERE result = 'damaged'
) as t1
JOIN  (
    SELECT ship, battle, result, date FROM Outcomes as o
    JOIN Battles as b ON o.battle = b.name
) as t2
ON t1.ship = t2.ship
WHERE t1.date < t2.date

# 38 !!
-- Find countries that ever had classes 
-- of both battleships (‘bb’) and cruisers (‘bc’).
SELECT DISTINCT country
FROM Classes
WHERE TYPE = 'bb'
AND country IN (
    SELECT DISTINCT country
    FROM Classes
    WHERE TYPE = 'bc'
)
     

-- 21.01.21
SELECT LENGTH(model) FROM Product p ;
# 36
 -- List the names of lead ships in the database 
 -- (including the Outcomes table).

Select name from ships where name = class
union
select hip from outcomes join classes on outcomes.ship = classes.class

# 35
-- Find models in the Product table consisting 
-- either of digits only or Latin letters 
-- (A-Z, case insensitive) only.
-- Result set: model, type.

SELECT * FROM Product p 
WHERE 
    model NOT REGEXP '[^0-9]' OR 
    model NOT REGEXP '[^A-Z]' OR 
    model NOT REGEXP '[^a-z]';

SELECT model, type FROM Product p 
WHERE 
    model NOT LIKE '%[^0-9]%' OR 
    model NOT LIKE '%[^A-Z]%' OR 
    model NOT LIKE '%[^a-z]%';

--------------------------
--------------------------
SHOW INDEX FROM passports;

SELECT * FROM products;
SELECT name, price FROM products;
SELECT * FROM products WHERE price < 3000;
SELECT name, price FROM products WHERE price >= 10000;
SELECT name FROM products WHERE count = 0;

-- Выберите из таблицы products название (name) и цены (price) товаров, стоимостью до 4000 включительно.
SELECT name, price FROM products WHERE price <= 4000;

SELECT * FROM users
WHERE country = 'RU' or country = 'BL' or country = 'UA'

SELECT * FROM users WHERE country IN ('BL', 'RU', 'UA') AND price < 1000

SELECT * FROM products
WHERE price <= 4000 and price >= 10000

SELECT * FROM products WHERE price BETWEEN 4000 AND 20000 OR country = 'RU'


-- Выберите из таблицы orders все заказы кроме отмененных. У отмененных заказов status равен "cancelled".
SELECT * FROM orders WHERE status != 'cancelled';

-- Выберите из таблицы orders все заказы содержащие более 3 товаров (products_count).
-- Вывести нужно только номер (id) и сумму (sum) заказа.
SELECT id, sum FROM orders WHERE products_count > 3;

-- (!!!)
-- Выберите из таблицы orders все отмененные (cancelled) и возвращенные (returned) товары.
-- Используйте IN.
SELECT * FROM orders WHERE status in ('cancelled', 'returned');

-- Выберите из таблицы orders все заказы, у которых сумма (sum) больше 3000 или количество товаров (products_count) от 3 и больше.
SELECT * FROM orders WHERE sum > 3000 or products_count >= 3;

-- Выберите из таблицы orders все заказы, у которых сумма (sum) от 3000 и выше, а количество товаров (products_count) меньше 3.
SELECT * FROM orders WHERE sum >= 3000 and products_count < 3;

-- Выберите из таблицы orders все отмененные заказы стоимостью от 3000 до 10000 рублей.
-- Используйте BETWEEN.
SELECT * FROM orders 
    WHERE sum BETWEEN 3000 and 10000 AND status = 'cancelled';

SELECT mark, model, year, power from cars
WHERE mark = 'Nissan' 
    AND year BETWEEN 2009 AND 2017
    AND sold = True 
    AND dealer_id IS NOT NULL
ORDER BY power;    

-- (!!!)
-- Выберите из таблицы orders все отмененные заказы исключая заказы стоимостью от 3000 до 10000 рублей.
SELECT * FROM orders 
    WHERE status = 'cancelled' 
          AND sum NOT BETWEEN 3000 AND 10000;

-- !!!!!!!!!!!!!  ОШИБКА
SELECT * FROM team WHERE level='senior' AND level='middle'; --(OR)

-- (!!!!)
SELECT * FROM team 
WHERE (basic_language='python' OR basic_language='php') AND level='middle'; 

-- Выберите из таблицы products все товары в порядке возрастания цены (price).
SELECT * FROM products ORDER BY price;

-- Выберите из таблицы products все товары в порядке убывания цены.
-- Выведите только имена (name) и цены (price).
SELECT name, price FROM products ORDER BY price DESC;

-- Выберите из таблицы products все товары стоимостью от 5000 и выше в 
-- порядке убывания цены (price).
SELECT * FROM products WHERE price >= 5000 ORDER BY price DESC;

-- Выберите из таблицы products все товары стоимостью до 3000 рублей 
-- отсортированные в алфавитном порядке. Вывести нужно только имя (name), 
-- количество (count) и цену (price).
SELECT name, countprice, FROM products WHERE price < 3000 ORDER BY name;

-- Выберите из таблицы users фамилии (last_name) и имена (first_name) всех 
-- пользователей.
-- Данные должны быть отсортированы сначала по фамилии, а затем по имени.
SELECT last_name, first_name FROM users
ORDER BY last_name, first_name;

-- Выберите из таблицы users всех пользователей с зарплатой от 40 000 рублей -- и выше. Данные нужно сначала отсортировать по убыванию зарплаты (salary), -- а затем в алфавитном порядке по имени (first_name).
SELECT * FROM users WHERE salary >= 40000
ORDER BY salary DESC, first_name;

-- (!!!)
-- Выберите сотрудников из таблицы users с зарплатой (salary) меньше 30 000 
-- рублей и отсортируйте данные по дате рождения (birthday). Сотрудников с 
-- нулевой зарплатой выбирать не нужно.
SELECT * FROM users WHERE salary < 30000 or salary != 0
ORDER BY birthday;
-- (НЕВЕРНО) 
SELECT * FROM users WHERE salary < 30000 or salary != 0
ORDER BY birthday;

1.5
SELECT * FROM products WHERE count > 0 ORDER BY price DESC LIMIT 5,5;
SELECT * FROM products WHERE count > 0 ORDER BY price DESC LIMIT 5,5;

-- Выберите из таблицы orders 5 самых дорогих заказов за всё время.
-- Данные нужно отсортировать в порядке убывания цены.
-- Отмененные заказы не учитывайте.
SELECT * FROM orders WHERE status != 'cancelled'
ORDER BY sum DESC LIMIT 5;

-- Выберите из таблицы products название и цены трех самых дешевых товаров, 
-- которые есть на складе.
SELECT name, price FROM products 
WHERE count != 0
ORDER BY price LIMIT 3;


-- Выберите из таблицы orders три последних заказа (по дате date) стоимостью 
-- от 3000 рублей и выше.
-- Данные отсортируйте по дате в обратном порядке.
SELECT * FROM orders 
WHERE sum >= 3000
ORDER BY date DESC
LIMIT 3;

-- Сайт выводит товары по 5 штук. Выберите из таблицы products товары, 
-- которые пользователи увидят на 3 странице каталога при сортировке в 
-- порядке возрастания цены (price).
SELECT * FROM products
ORDER BY price
LIMIT 10, 5;

-- В таблице products 17 записей. Сайт выводит название (name) и цену (price) 
-- товаров в алфавитном порядке, по 6 записей на страницу. Напишите SQL 
-- запрос для получения списка товаров для формирования последней страницы 
-- каталога.
-- Товары, которых нет на складе, выводить не надо (таких товаров 3).
SELECT name, price WHERE count != 0
ORDER BY name
LIMIT 13, 6;

2.1
INSERT INTO users (id, first_name, last_name, birthday)
VALUES (6, '...', '...', '2001-04-14')

-- Добавьте в таблицу orders данные о новом заказе стоимостью 3000 рублей. В -- заказе 3 товара (products).
INSERT INTO orders (id, products, sum) VALUES (6, 3, 3000);

INSERT INTO orders (id, products, sum) VALUES (6, 3, 3000);

INSERT  INTO products (id, name, count, price) VALUES (7, 'Xbox', 3, 30000);

INSERT INTO products (id, name, count, price) 
VALUES (8, 'iMac 21', 0, 100100);

INSERT INTO users (id, first_name, last_name , birthday )
VALUES (9, 'Антон', 'Пепеляев', '1992-07-12')

INSERT INTO users SET first_name = 'Никита', last_name = 'Петров';

INSERT INTO products (id, name, count, price)
 VALUES 
 (8, 'iPhone 7', 1, 59990),
 (9, 'iPhone 8', 3, 64990),
 (10, 'iPhone X', 2, 79900);

UPDATE products SET name = '' WHERE name = '';
UPDATE ... SET price = price * 0.9 ORDER BY price DESC LIMIT 1;

-- Увеличьте в таблице users сотрудникам, у которых зарплата менее 20 000 
-- рублей, зарплату (salary) на 10%.
UPDATE users SET salary = salary + salary * 0.1 WHERE salary < 20000; 


-- В магазин привезли 2 упаковки Сникерса и 2 упаковки Марса. В 
-- каждой упаковке по 20 шоколадок. Обновите данные так, чтобы они 
-- отражали правильное количество шоколадок.
UPDATE products SET count=count + 40 
WHERE name IN ('Сникерс', 'Марс');


DELETE FROM users WHERE last_visit_date IS_NULL;
DELETE FROM users;
TRUNCATE TABLE cars; 

-- Удалите из таблицы cars все японские автомобили мощностью менее 
-- 80 и более 130 лс. (включая крайние значения)(country, power).
DELETE FROM cars 
 WHERE (power NOT BETWEEN 79 AND 129) AND (country='JP')

-- заглушка для таблицы
CREATE TABLE user2 (
    id INT,                  --   -+2e+9 
    id INT UNSIGNED,         --   + 4e+9 
    first_name VARCHAR(20),
    last_name VARCHAR(40),
    birthday DATE,           -- DATETIME, TIMESTAMP
    age TINYINT,             --   -128...127  (JAVA's short) 
    active BOOL,
    rate FLOAT

)

TINYINT < SMALLINT < MEDIUMINT < INT < BIGINT
FLOAT < DOUBLE < DECIMAL

DESCRIBE orders;
DROP TABLE products;

------------ ENUM('..', '...'), SET('wifi,tv')-----------
state ENUM(
        'new', 'cancelled', 'delivered', 'completed'
        ) NOT NULL DEFAULT 'new'

FIND_IN_SET('wifi', facilities) AND FIND_IN_SET('tv', facilities);

-----------------------------
-- ИНДЕКСЫ

CREATE INDEX col_idx ON table_name(col)
or
CREATE TABLE table_name (
    col1 ...
    ...
    INDEX col3_idx (col3)
);

DROP INDEX email ON users;

---------------------------
ALTER TABLE users ADD col_name DATE NULL ... AFTER col_name; 
ALTER TABLE users ADD col_name DATE NULL ... FIRST;
ALTER TABLE products 
ADD FOREIGN KEY (category_id) REFERENCES categories (id);

ALTER TABLE users MODIFY col_name VARCHAR(50) ...; 

ALTER TABLE users CHANGE nmae name VARCAHR(50) ...;

ALTER TABLE users DROP COLUMN birthday


# multiple
ALTER TABLE users
 ADD COLUMN (
  ...
  birthday DATE DEFAULT NULL,
  ...
);

ALTER TABLE passports
MODIFY  series VARCHAR(4) NOT NULL,
MODIFY number VARCHAR(6) NOT NULL,
ADD UNIQUE INDEX passport (series, number);


RENAME TABLE product TO products, log TO logs;

---------------------------
--СПЕЦСИМВОЛЫ (% и _) И ШАБЛОНЫ

SELECT * FROM users WHERE f_name LIKE 'нАта'; --Ната, ната
    equals
SELECT * FROM users WHERE f_name = 'нАталья';

SELECT * FROM users WHERE f_name LIKE BINARY 'нАта'; --нАта

--шаблон поиска: всё, начиная с "н" и заканичая "а"
SELECT * FROM users WHERE f_name LIKE 'н%а';

--в середине % опечатка
SELECT * FROM users WHERE f_name LIKE '%\%%';

-- ровно 6 цифр, которые начинаются с 89
SELECT * FROM users WHERE phone LIKE '89____';
SELECT * FROM users WHERE phone NOT LIKE '89____';

---------------------------
-- полнотекстовый поиск отсортирован по релевантсности

CREATE FULLTEXT INDEX idx_name ON products(name);

SELECT * FROM products
 WHERE MATCH(name) AGAINST ('микроволновая печь')

-- https://stepik.org/lesson/206823/step/1?unit=180524 05:04
SELECT * FROM products
 WHERE MATCH(name) 
 AGAINST ('микроволновая печь' IN BOOLEAN MODE)
 AGAINST ('+микроволновая +печь' IN BOOLEAN MODE) + обязательно
 AGAINST ('-микроволновая +печь' IN BOOLEAN MODE) - отсутствие
 AGAINST ('~микроволновая +печь' IN BOOLEAN MODE) ~ обесц значим
 AGAINST ('микроволнов* печ*' IN BOOLEAN MODE)  * любые символы
 AGAINST ('"микроволновая печь"' IN BOOLEAN MODE) "" точно

CREATE FULLTEXT INDEX search ON products(name, description);
SELECT * FROM products 
WHERE MATCH(name, description) AGAINST ('платье детское');

SELECT id, subject FROM forum 
 WHERE MATCH(subject, post) 
 AGAINST ('ошибк* проблем*' IN BOOLEAN MODE);

 ------------------------ МАТЕМАТИЧЕСКИЕ ФУНКЦИИ 
 
 ROUND(col, n), TRUNCATE(col, n), FLOOR(col), CEILING(col)

 SELECT id, name, ROUND(rating, 1) as rating FROM ...

 ------------------------ СТРОКОВЫЕ ФУНКЦИИ
 LENGTH(col) - байтах, CHAR_LENGTH(col), CONCAT, UPPER, TRIM 
 CONCAT(l_name, ' ', LEFT(f_name, 1), '.') as fi
 CONCAT_WS(' ', '12', '34'), LPAD( string, length, pad_string )
 SELECT SUBSTR('2301148145', 1, 4)  # 2301
 SELECT SUBSTR('2301148145', -6)    # 148145
 SELECT TRIM(TRAILING '.' FROM 'google.com');
TRIM( [ LEADING TRAILING BOTH ] [ trim_character FROM ] string )
 ------------------------ ФУНКЦИИ ДАТЫ
 NOW(), YEAR(birthday), DAY, MONTH, WEEK, DAYNAME, MONTHNAME, MINUTE, SECOND, HOUR, INTERVAL, DATE_FORMAT, DATE, TIME, DAYOFWEEK, SEC_TO_TIME(178), TIME_TO_SEC 
 
 NOW = SYSDATE = CURRENT_TIMESTAMP
 CURDATE = CURRENT_DATE
 CURTIME = CURRENT_TIME

 TIME = HOUR - MINUTE - SECOND
 DATE = YEAR - MONTH - DAY

 WHERE MONTH(birthday) = MONTH(NOW())
 WHERE date_joined > NOW() - INTERVAL 7 DAY; 
 DATE_FORMAT(date_joined + INTERVAL 1 MONTH, "%d.%m.%Y %H:%i")

 ------------------------------ АГРЕГИРУЮЩИЕ ФУНКЦИИ
 count, min, max, avg

 ------------------------------- GROUP BY

 SELECT 
    YEAR(date) AS year, 
    MONTH(date) AS month, 
    SUM(amount) AS income, 
    COUNT(*) AS orders  
FROM orders 
 WHERE status LIKE 's%'
 GROUP BY YEAR(date), MONTH(date)
 ORDER BY YEAR(date), MONTH(date);

--------------------------------- UNION
 (SELECT ... FROM ...) 
 UNION 
 (SELECT ... FROM ...)
 ORDER BY ... ;

 SELECT * FROM (
    SELECT * FROM advs
    UNION
    SELECT * FROM closed_advs
) AS t
WHERE ...
ORDER BY ...;


---------------------------  9.4 Отношение один к одному
DELETE FROM table2
    USING table1 JOIN table2
    WHERE 
    table2.id = table1.id AND 
    table1.id < 10;

----------------------------  FOREIGN KEY

CREATE TABLE users_data (
    ...
    FOREIGN KEY (id) REFERENCES users (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);    

ON DELETE SET NULL
ON DELETE RESTRICT если существуют ключи в дочерних (нельзя уд)

CREATE TABLE products_details (
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    product_id INT UNSIGNED NOT NULL UNIQUE KEY,
    description TEXT,
    FOREIGN KEY (product_id) REFERENCES products (id)
);

--------------------- 9.7 Создание связей один-ко-многим
ALTER TABLE artists
    ADD COLUMN genre_id INT UNSIGNED NULL;
ALTER TABLE artists
    ADD FOREIGN KEY (genre_id) REFERENCES genres(id)
    ON DELETE SET NULL;
ALTER TABLE ...
    DROP FOREIGN KEY ...

ALTER TABLE artists ADD (
    genre_id INT UNSIGNED NULL,
    FOREIGN KEY (genre_id) REFERENCES genres(id)
    ON DELETE SET NULL
);

------------------------------ JOIN

SELECT c.*, p.* FROM categories as c
JOIN products as p ON p.category_id = c.id 
WHERE c.parent_id IS NULL;


--------------------------------- ANY, ALL
SELECT name, price FROM products 
WHERE price > ANY (
    SELECT price FROM products WHERE category_id = (
        SELECT id FROM categories WHERE name = 'Фрукты'
    )
)

---------------------------------- EXISTS
SELECT * FROM users AS u
WHERE NOT EXISTS (
    SELECT * FROM users_roles ur WHERE u.id = ur.user_id
);

SELECT u.id, u.first_name, u.last_name FROM users u 
LEFT JOIN users_roles ur ON ur.user_id = u.id
WHERE ur.user_id IS NULL;

SELECT * FROM users WHERE id NOT IN (
    SELECT user_id FROM users_roles
);


----------------------- 10.4 Запросы, возвращающие несколько столбцов
SELECT * FROM products 
WHERE (id, price) NOT IN (SELECT * FROM old_prices)

----------------------- 10.5 Подзапросы в конструкции FROM
SELECT * FROM (
    SELECT * FROM cars ORDER BY price
) as best_cars
ORDER BY price

SELECT * FROM ... 
JOIN (SELECT * FROM ...) as t ON WHERE ...

------------------------10.6 Подзапросы в конструкции INSERT
INSERT IGNORE INTO paypal_payments (
    SELECT id, user_id, date, amount FROM payments
    WHERE source = 'paypal'
)

