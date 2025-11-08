-- Источник заданий: Симулятор SQL Karpov Courses --

-- Оконные функции --

/* Задание 1
Примените оконные функции к таблице `products` и с помощью ранжирующих функций упорядочьте все товары по цене — от самых дорогих к самым дешёвым. 
Добавьте в таблицу следующие колонки:

- Колонку `product_number` с порядковым номером товара (функция `ROW_NUMBER`).
- Колонку `product_rank` с рангом товара с пропусками рангов (функция `RANK`).  
- Колонку `product_dense_rank` с рангом товара без пропусков рангов (функция `DENSE_RANK`).  

Не забывайте указывать в окне сортировку записей — без неё ранжирующие функции могут давать некорректный результат, если таблица заранее не отсортирована. 
Деление на партиции внутри окна сейчас не требуется. Сортировать записи в результирующей таблице тоже не нужно. */

-- Решение:
SELECT product_id,
       name,
       price,
       row_number() OVER(ORDER BY price desc) product_number,
       rank() OVER(ORDER BY price desc) product_rank,
       dense_rank() OVER(ORDER BY price desc) product_dense_rank
FROM   products
ORDER BY price desc

----------------------------------------------------------------------------
/* Задание 2:
Примените оконную функцию к таблице `products` и с помощью агрегирующей функции в отдельной колонке для каждой записи проставьте цену самого дорогого товара. Колонку с этим значением назовите `max_price`.

Затем для каждого товара посчитайте долю его цены в стоимости самого дорогого товара. Полученные доли округлите до двух знаков после запятой. Колонку с долями назовите `share_of_max`.

Выведите всю информацию о товарах, включая значения в новых колонках. Результат отсортируйте сначала по убыванию цены товара, затем по возрастанию id товара. */

-- Решение:
SELECT product_id,
       name,
       price,
       max(price) OVER() max_price,
       round(price / max(price) OVER(), 2) share_of_max
FROM   products
ORDER BY price desc, product_id asc

----------------------------------------------------------------------------
/* Задание 3:
Примените две оконные функции к таблице `products`. Одну с агрегирующей функцией `MAX`, а другую с агрегирующей функцией `MIN` — для вычисления максимальной и минимальной цены. Для двух окон задайте инструкцию `ORDER BY` по убыванию цены. Поместите результат вычислений в две колонки `max_price` и `min_price`.

Выведите всю информацию о товарах, включая значения в новых колонках. Результат отсортируйте сначала по убыванию цены товара, затем по возрастанию id товара. */

Решение:
SELECT product_id,
       name,
       price,
       max(price) OVER(ORDER BY price desc) max_price,
       min(price) OVER(ORDER BY price desc) min_price
FROM   products
ORDER BY price desc, product_id asc

----------------------------------------------------------------------------
/* Задание 4:
Сначала на основе таблицы `orders` сформируйте запрос, который вернет таблицу с общим числом заказов по дням. При подсчёте числа заказов не учитывайте отменённые заказы (их можно определить по таблице `user_actions`). Колонку с днями назовите `date`, а колонку с числом заказов — `orders_count`.

Затем поместите полученную таблицу в подзапрос и примените к ней оконную функцию в паре с агрегирующей функцией `SUM` для расчёта накопительной суммы числа заказов. Не забудьте для окна задать инструкцию `ORDER BY` по дате.

Колонку с накопительной суммой назовите `orders_count_cumulative`. В результате такой операции значение накопительной суммы для последнего дня должно получиться равным общему числу заказов за весь период.

Сортировку результирующей таблицы делать не нужно.*/

-- Решение:
SELECT date,
       orders_count,
       sum(orders_count) OVER(ORDER BY date)::int orders_count_cumulative
FROM   (SELECT DISTINCT o.creation_time::date date,
                        count(o.order_id) OVER(PARTITION BY o.creation_time::date)::int orders_count
        FROM   orders o join user_actions u
                ON u.order_id = o.order_id
        WHERE  u.order_id not in (SELECT order_id
                                  FROM   user_actions
                                  WHERE  action = 'cancel_order')) t

----------------------------------------------------------------------------
/* Задание 5:
Для каждого пользователя в таблице `user_actions` посчитайте порядковый номер каждого заказа.

Для этого примените оконную функцию `ROW_NUMBER`, используйте id пользователей для деления на патриции, а время заказа для сортировки внутри патриции. Отменённые заказы не учитывайте.

Новую колонку с порядковым номером заказа назовите `order_number`. Результат отсортируйте сначала по возрастанию id пользователя, затем по возрастанию порядкового номера заказа.

Добавьте в запрос оператор `LIMIT` и выведите только первые 1000 строк результирующей таблицы. */

-- Решение:
SELECT user_id,
       order_id,
       time,
       row_number() OVER(PARTITION BY user_id
                         ORDER BY time asc) order_number
FROM   user_actions
WHERE  order_id not in (SELECT order_id
                        FROM   user_actions
                        WHERE  action = 'cancel_order')
ORDER BY user_id asc 
limit 1000

----------------------------------------------------------------------------
/* Задание 6:
Дополните запрос из предыдущего задания и с помощью оконной функции для каждого заказа каждого пользователя рассчитайте, сколько времени прошло с момента предыдущего заказа. 

Для этого сначала в отдельном столбце с помощью `LAG` сделайте смещение по столбцу `time` на одно значение назад. Столбец со смещёнными значениями назовите `time_lag`. Затем отнимите от каждого значения в колонке `time` новое значение со смещением (либо можете использовать уже знакомую функцию `AGE`). Колонку с полученным интервалом назовите `time_diff`. Менять формат отображения значений не нужно, они должны иметь примерно следующий вид:

3 days, 12:18:22

По-прежнему не учитывайте отменённые заказы. Также оставьте в запросе порядковый номер каждого заказа, рассчитанный на прошлом шаге. Результат отсортируйте сначала по возрастанию id пользователя, затем по возрастанию порядкового номера заказа.

Добавьте в запрос оператор LIMIT и выведите только первые 1000 строк результирующей таблицы. */

-- Решение:
SELECT user_id,
       order_id,
       time,
       row_number() OVER(PARTITION BY user_id
                         ORDER BY time asc) order_number,
       lag(time, 1) OVER(PARTITION BY user_id
                         ORDER BY time asc) time_lag,
       age(time, lag(time, 1) OVER(PARTITION BY user_id
                                   ORDER BY time asc)) time_diff
FROM   user_actions
WHERE  order_id not in (SELECT order_id
                        FROM   user_actions
                        WHERE  action = 'cancel_order')
ORDER BY user_id asc 
limit 1000

----------------------------------------------------------------------------
/* Задание 7:
На основе запроса из предыдущего задания для каждого пользователя рассчитайте, сколько в среднем времени проходит между его заказами. Посчитайте этот показатель только для тех пользователей, которые за всё время оформили более одного неотмененного заказа.

Среднее время между заказами выразите в часах, округлив значения до целого числа. Колонку со средним значением времени назовите `hours_between_orders`. Результат отсортируйте по возрастанию id пользователя.

Добавьте в запрос оператор `LIMIT` и включите в результат только первые 1000 записей. */

**Решение:**
SELECT t.user_id,
       round(avg(extract(epoch
FROM   (t.order_time - t.prev_order_time)) / 3600))::int as hours_between_orders
FROM   (SELECT ua.user_id,
               ua.time as order_time,
               lag(ua.time) OVER (PARTITION BY ua.user_id
                                  ORDER BY ua.time) as prev_order_time
        FROM   user_actions ua
        WHERE  ua.action = 'create_order'
           and ua.order_id not in (SELECT order_id
                                FROM   user_actions
                                WHERE  action = 'cancel_order')) t
WHERE  t.prev_order_time is not null
   and t.user_id in (SELECT user_id
                  FROM   user_actions
                  WHERE  action = 'create_order'
                     and order_id not in (SELECT order_id
                                       FROM   user_actions
                                       WHERE  action = 'cancel_order')
                  GROUP BY user_id having count(order_id) > 1)
GROUP BY t.user_id
ORDER BY t.user_id 
limit 1000

----------------------------------------------------------------------------