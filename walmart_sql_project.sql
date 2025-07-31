--EDA

SELECT *
FROM walmart;


DROP TABLE walmart_clean_data;

SELECT COUNT(*)
FROM walmart;


SELECT 
	payment_method,
	COUNT(*) AS number_of_transactions 
FROM walmart;
GROUP BY 1;

SELECT 
	DISTINCT category
FROM walmart;

SELECT COUNT(DISTINCT branch)
FROM walmart;

SELECT COUNT(DISTINCT city)
FROM walmart;

SELECT MAX(quantity)
FROM walmart;

SELECT SUM(quantity)
FROM walmart;

-- Business Problems

--1.Find Different payment methods and number of transcations, number of qty sold

SELECT
	payment_method,
	COUNT(*) AS number_of_transactions,
	SUM(quantity) AS qty_sold
FROM walmart
GROUP BY 1;

--2.Identify the highest-rated category in each branch, displaing the branch, category, avg rating


SELECT
    branch,
    category,
    avg_rating,
    RANK() OVER(PARTITION BY branch ORDER BY avg_rating DESC) AS rank_in_branch
FROM (
    SELECT
        branch,
        category,
        AVG(rating) AS avg_rating
    FROM walmart
    GROUP BY 1,2
) AS sub;


SELECT *
FROM (
    SELECT
        branch,
        category,
        avg_rating,
        RANK() OVER(PARTITION BY branch ORDER BY avg_rating DESC) AS rank_in_branch
    FROM (
        SELECT
            branch,
            category,
            AVG(rating) AS avg_rating
        FROM walmart
        GROUP BY 1, 2
    ) AS sub
) AS ranked
WHERE rank_in_branch = 1;


--3.Identify the busiest day for each branch based on the number of transactions
SELECT *
FROM (
    SELECT 
        branch,
        TO_CHAR(TO_DATE(date, 'DD/MM/YY'), 'Day') AS day_name,
        COUNT(*) AS num_transactions,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rank
    FROM walmart
    GROUP BY branch, TO_CHAR(TO_DATE(date, 'DD/MM/YY'), 'Day')
) AS ranked_days
WHERE rank = 1;

--4. Calculate the total quantity of items sold per payment method. list payment method and the total quantity
SELECT 
	payment_method,
	SUM(quantity) AS total_quantity
FROM walmart
GROUP BY 1

--5. Determine the average, minimum, and maximum rating of category for each city.
--list the city, average rating, min rating and max rating
SELECT
	city,
	category,
	MIN(rating) AS min_rating,
	ROUND(AVG(rating::NUMERIC), 2),
	MAX(rating) AS max_rating
FROM walmart
GROUP BY 1,2;


--6. Calculate the total profit for each category by considering total_profit as (unit price * quantity* profit margin)

SELECT
	category,
	SUM(total) as revenue,
	ROUND(
		SUM(total::numeric * profit_margin::numeric), 2
	) AS total_profit
FROM walmart
GROUP BY 1
ORDER BY 3 DESC;


--7. Determine the most common paymenet method for each branch. display branch and the preferred payment method
 

WITH cte
AS 
	(
	SELECT
		branch,
		payment_method,
		COUNT(*) as total_transactions,
		RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rank
	FROM walmart
	GROUP BY 1,2 
	)
SELECT *
FROM cte
WHERE rank = 1


--8. Categorise sales into 3 groups - morning, afternoon, evening
-- find out which of shift and the number of invoices


WITH new_time AS (
  SELECT
    time,
    TO_TIMESTAMP(time, 'HH24:MI:SS')::time AS order_time
  FROM walmart
)
SELECT 
  order_time,
  CASE 
    WHEN order_time >= TIME '06:00' AND order_time < TIME '12:00' THEN 'Morning'
    WHEN order_time >= TIME '12:00' AND order_time < TIME '18:00' THEN 'Afternoon'
    WHEN order_time >= TIME '18:00' AND order_time < TIME '24:00' THEN 'Evening'
    ELSE 'Invalid'
  END AS shift,
  COUNT(*) AS orders
FROM new_time
GROUP BY shift, order_time
ORDER BY orders DESC;


--9. identify 5 branches with highest decrease ratio in revenue compare to last year (current year 2023, last year 2022)


WITH revenue_2022
AS
(
	SELECT 
		branch,
		SUM(total) AS revenue
	FROM walmart
	WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2022
	GROUP BY 1
),
revenue_2023
AS
(
SELECT 
		branch,
		SUM(total) AS revenue
	FROM walmart
	WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2023
	GROUP BY 1
)
SELECT 
	ls.branch,
	ls.revenue AS last_year_revenue,
	cs.revenue AS current_year_revenue,
	ROUND((ls.revenue - cs.revenue)::numeric/ls.revenue::numeric * 100,2) AS revenue_decrease_ratio
FROM revenue_2022 AS ls
JOIN revenue_2023 AS cs
ON ls.branch=cs.branch
WHERE
	ls.revenue > cs.revenue
ORDER BY 4 DESC
LIMIT 5
