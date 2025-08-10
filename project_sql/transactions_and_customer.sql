CREATE TABLE transactions_info (
    date_new DATE,
    Id_check INT,
    ID_client INT,
    Count_products DECIMAL(10, 3),
    Sum_payment DECIMAL(10, 2)
);

drop table transactions_info;
select * from transactions_info;


-- 1. Найдём клиентов, у которых есть покупки в каждом месяце
WITH active_clients AS (
    SELECT 
        ID_client,
        COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) AS months_with_purchases
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY ID_client
    HAVING months_with_purchases = 12  -- Только те, у кого 12 месяцев покупок
)

-- 2. Добавим информацию о клиентах и их тратах
SELECT 
    c.Id_client, 
    c.Gender, 
    c.Age, 
    SUM(t.Sum_payment) AS total_spent,  -- Сумма всех покупок за год
    COUNT(t.date_new) AS total_transactions  -- Количество покупок
FROM active_clients ac
JOIN customer_info c ON ac.ID_client = c.Id_client
JOIN transactions_info t ON ac.ID_client = t.ID_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY c.Id_client, c.Gender, c.Age
ORDER BY total_spent DESC;  -- Сортируем по сумме покупок

-- 2. Средний чек, средняя сумма покупок за месяц, общее количество операций
SELECT 
    ID_client,
    COUNT(*) AS total_transactions,   
    SUM(Sum_payment) / COUNT(*) AS avg_check,  
    SUM(Sum_payment) / 12 AS avg_monthly_spending,  
    SUM(Sum_payment) AS total_spent  
FROM transactions_info
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY ID_client;

-- 3. Помесячная статистика
SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS transaction_month,  -- Форматируем дату в формат "YYYY-MM"
    AVG(Sum_payment) AS avg_check_per_month,  
    COUNT(*) / COUNT(DISTINCT ID_client) AS avg_operations_per_client,  
    COUNT(DISTINCT ID_client) AS unique_clients  
FROM transactions_info
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY transaction_month
ORDER BY transaction_month;


-- 4. Доля операций и выручки каждого месяца
SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS transaction_month,
    COUNT(*) AS monthly_transactions,  
    SUM(Sum_payment) AS monthly_revenue,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM transactions_info WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01') AS percent_operations,
    SUM(Sum_payment) * 100.0 / (SELECT SUM(Sum_payment) FROM transactions_info WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01') AS percent_revenue
FROM transactions_info
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY transaction_month
ORDER BY transaction_month;

-- 5. Соотношение M/F/NA (мужчины, женщины, неизвестно)
SELECT 
    DATE_FORMAT(t.date_new, '%Y-%m') AS transaction_month,
    c.Gender,
    COUNT(*) AS transactions,
    SUM(t.Sum_payment) AS total_spent,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) AS percent_transactions,
    SUM(t.Sum_payment) * 100.0 / SUM(SUM(t.Sum_payment)) OVER(PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) AS percent_revenue
FROM transactions_info t
JOIN customer_info c ON t.ID_client = c.Id_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY transaction_month, c.Gender
ORDER BY transaction_month, c.Gender;

-- 6. Группировка по возрасту
SELECT 
    CASE 
        WHEN Age BETWEEN 10 AND 19 THEN '10-19'
        WHEN Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN Age BETWEEN 40 AND 49 THEN '40-49'
        WHEN Age BETWEEN 50 AND 59 THEN '50-59'
        WHEN Age BETWEEN 60 AND 69 THEN '60-69'
        WHEN Age IS NULL THEN 'Unknown'
        ELSE '70+'
    END AS age_group,
    COUNT(DISTINCT t.ID_client) AS total_clients,
    COUNT(*) AS total_transactions,
    SUM(t.Sum_payment) AS total_spent,
    AVG(t.Sum_payment) AS avg_check
FROM transactions_info t
JOIN customer_info c ON t.ID_client = c.Id_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY age_group
ORDER BY age_group;


-- 7. Квартальная статистика
SELECT 
    CONCAT(YEAR(date_new), '-Q', QUARTER(date_new)) AS transaction_quarter,
    COUNT(*) AS total_transactions,
    SUM(Sum_payment) AS total_spent,
    AVG(Sum_payment) AS avg_check
FROM transactions_info
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY transaction_quarter
ORDER BY transaction_quarter;





