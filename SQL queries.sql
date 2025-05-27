select top 10 * from gold.fact_sales;

--Over year Analysis--
--Total sales, customer count, total quantity changes over years----
DROP VIEW dbo.Over_year_analysis;

CREATE VIEW gold.Over_year_analysis AS(
select 
YEAR(order_date) as order_year, 
SUM(sales_amount) as total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
from 
gold.fact_sales
where order_date is not null
group by YEAR(order_date))
--order by YEAR(order_date)




--Over month Analysis--
select 
MONTH(order_date) as order_month, 
YEAR(order_date) as order_year, 
SUM(sales_amount) as total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
from 
gold.fact_sales
where order_date is not null
group by MONTH(order_date)
order by MONTH(order_date) 

--by month and year----
select 
YEAR(order_date) as order_year,
MONTH(order_date) as order_month, 
SUM(sales_amount) as total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
from 
gold.fact_sales
where order_date is not null
group by YEAR(order_date) ,MONTH(order_date)
order by YEAR(order_date) ,MONTH(order_date) 

---Date, mnoth and year combined to a single column, always the first date of month--
select 
DATETRUNC(month,order_date) as order_date,
SUM(sales_amount) as total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
group by DATETRUNC(month,order_date)
order by DATETRUNC(month,order_date)

---Formatted month and year--
select 
FORMAT(order_date, 'yyyy-MMM') as order_date,
SUM(sales_amount) as total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
group by FORMAT(order_date, 'yyyy-MMM')
order by FORMAT(order_date, 'yyyy-MMM')


--Cumulative Analysis using aggregate window functions--
--Calculate the total sales per month—
--Running total of sales over time--
SELECT order_date,
total_sales,
SUM(total_sales) OVER (PARTITION BY order_date ORDER BY order_date) AS running_total_sales --Distinct cumulative sum for each year--
FROM
(select 
DATETRUNC(month,order_date) as order_date,
SUM(sales_amount) as total_sales
from gold.fact_sales
where order_date is not null
group by DATETRUNC(month,order_date)
)t

----cumulative sales over year--
DROP VIEW gold.cumulative_sales_over_year

CREATE VIEW gold.cumulative_sales_over_year AS(
SELECT order_year,
total_sales,
SUM(total_sales) OVER (ORDER BY order_year) AS running_total_sales --Distinct cumulative sum for each year--
FROM
(select 
YEAR(order_date) as order_year,
SUM(sales_amount) as total_sales
from gold.fact_sales
where order_date is not null
group by YEAR(order_date) 
)t)

----cumulative sales & moving average price over year--
SELECT order_year,
total_sales,
SUM(total_sales) OVER (ORDER BY order_year) AS running_total_sales, --Distinct cumulative sum for each year--
AVG(avg_price) OVER (ORDER BY order_year) AS moving_average_price --Distinct cumulative sum for each year--
FROM
(select 
DATETRUNC(year,order_date) as order_year,
SUM(sales_amount) as total_sales,
AVG(price) as avg_price
from gold.fact_sales
where order_date is not null
group by DATETRUNC(year,order_date)
)t

/*Analyse the yearly performance of products by comparing each product’s sales to both
its average sales performance and the previous year’s sales.*/

USE master;
GO
WITH yearly_product_sales AS (
SELECT 
p.product_name ,
YEAR(s.order_date) As order_year,
SUM(s.sales_amount) as current_sales
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON p.product_key = s.product_key
WHERE s.order_date is not null
GROUP BY 
YEAR(s.order_date),
p.product_name)
SELECT 
product_name,
order_year,
current_sales,
AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
	WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
	ELSE 'AVG'
END avg_change,
--year over year analysis--
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) prev_year_sales,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_prev_year,
CASE WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
	WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
	ELSE 'No Change'
END prev_year_change
FROM yearly_product_sales
ORDER BY product_name, order_year;





-----Which categories contribute the most to overall sales?-------
WITH category_sales AS
(SELECT 
category,
sum(sales_amount) as total_sales
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON p.product_key = s.product_key
group by category)
SELECT
category,
total_sales,
SUM(total_sales) OVER() Overall_sales,
CONCAT(ROUND(CAST(total_sales AS FLOAT)/(SUM(total_sales) OVER())*100,2), '%') as total_percentage
FROM category_sales
ORDER BY total_sales desc;

----Segment products into cost ranges and count how many products fall into each segment.---
WITH product_segments AS 
(SELECT
product_key,
product_name,
cost,
CASE WHEN cost < 100 THEN 'Below 100'
	 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
	 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
	 ELSE 'Above 1000'
END cost_range
FROM gold.dim_products)

SELECT 
cost_range,
COUNT(product_key) as total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products desc

/* Group cuastomers into three segments based on their spending behaviour;
-VIP: Customers with atleast 12 months of history and spending more than $5,000.
-Regular: Customers with atleast 12 months of history but spending $5,000or less.
-New: Customers with spending history less than 12 months
Find the total number of customers by each group*/
WITH customer_spending AS (
SELECT 
c.customer_key,
SUM(s.sales_amount) total_spend,
MIN(s.order_date) AS first_order_date,
MAX(s.order_date) AS last_order_date,
DATEDIFF (MONTH, MIN(s.order_date), MAX(s.order_date)) AS life_span
from gold.fact_sales s
join gold.dim_customers c
on s.customer_key = c.customer_key
GROUP BY c.customer_key)

SELECT
customer_key,
total_spend,
life_span,
CASE WHEN life_span >= 12 and total_spend > 5000 THEN 'VIP'
	 WHEN life_span >= 12 and total_spend <= 5000 THEN 'Regular'
	 ELSE 'New'
END customer_segment
FROM customer_spending;


WITH customer_spending AS (
SELECT 
c.customer_key,
SUM(s.sales_amount) total_spend,
MIN(s.order_date) AS first_order_date,
MAX(s.order_date) AS last_order_date,
DATEDIFF (MONTH, MIN(s.order_date), MAX(s.order_date)) AS life_span
from gold.fact_sales s
join gold.dim_customers c
on s.customer_key = c.customer_key
GROUP BY c.customer_key)

SELECT 
customer_segment,
COUNT(customer_key) as total_customers
FROM
(
	SELECT
	customer_key,
	CASE WHEN life_span >= 12 and total_spend > 5000 THEN 'VIP'
		 WHEN life_span >= 12 and total_spend <= 5000 THEN 'Regular'
		 ELSE 'New'
	END customer_segment
	FROM customer_spending)t
GROUP BY customer_segment
ORDER BY total_customers


---------------Final report--------------

DROP VIEW gold.customer_report;

CREATE VIEW gold.customer_report AS
WITH base_query AS (
SELECT
s.order_number,
s.product_key,
s.order_date,
s.sales_amount,
s.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name,' ',c.last_name) AS customer_name,
DATEDIFF(YEAR, c.birthdate, GETDATE()) AS age
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c
on s.customer_key = c.customer_key
WHERE s.order_date IS NOT NULL)

,customer_aggregation AS (

SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	MAX(order_date) AS last_order_date,
	DATEDIFF (MONTH, MIN(order_date), MAX(order_date)) AS life_span_in_months,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT product_key) AS total_products,
	SUM(quantity) as total_quantity
FROM
base_query
GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	age)

SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	CASE 
		WHEN age < 20  THEN 'Under 20'
		WHEN age BETWEEN 20 and 29 THEN '20-29'
		WHEN age BETWEEN 30 and 39 THEN '30-39'
		WHEN age BETWEEN 40 and 49 THEN '40-49'
		WHEN age BETWEEN 50 and 59 THEN '50-59'
		WHEN age BETWEEN 60 and 69 THEN '60-69'
		ELSE '70 and above'
	END AS age_group,
	CASE 
		WHEN life_span_in_months >= 12 and total_sales > 5000 THEN 'VIP'
		WHEN life_span_in_months >= 12 and total_sales <= 5000 THEN 'Regular'
		ELSE 'New'
	END AS customer_segment,
	last_order_date,
	DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency_in_months,
	life_span_in_months,
	total_sales,
	total_orders,
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE total_sales/total_orders 
	END AS Average_order_value,	
	total_products,
	total_quantity,
	CASE 
		WHEN life_span_in_months = 0 THEN total_sales
		ELSE total_sales/life_span_in_months 
	END AS average_monthly_spent

FROM
customer_aggregation;


SELECT * FROM gold.customer_report;


SELECT 
	age_group,
	customer_segment,
	recency_in_months,
	life_span_in_months,
	total_sales,
	total_orders,
	Average_order_value,	
	total_products,
	total_quantity,
	average_monthly_spent
FROM gold.customer_report;





SELECT 
age_group, 
COUNT(customer_number) as total_customers,
SUM(total_sales) AS total_sales
FROM gold.customer_report
GROUP BY age_group;

SELECT 
customer_segment, 
COUNT(customer_number) as total_customers,
SUM(total_sales) AS total_sales
FROM gold.customer_report
GROUP BY customer_segment;


-------------View for Product report---------------
CREATE VIEW gold.product_report AS
WITH base_query AS(
SELECT 
	s.order_number,
	s.order_date,
	s.customer_key,
	s.sales_amount,
	s.quantity,
	p.product_key,
	p.product_name,
	p.category,
	p.subcategory,
	p.cost
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON s.product_key = p.product_key
WHERE order_date IS NOT NULL
),
product_aggregation AS(

SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	MAX(order_date) AS last_sales_date,
	DATEDIFF (MONTH, MIN(order_date), MAX(order_date)) AS life_span_in_months,
	COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) as total_quantity,
	ROUND(AVG(CAST(sales_amount AS FLOAT)/NULLIF(quantity,0)),1) AS average_selling_price
FROM base_query
GROUP BY
	product_key,
	product_name,
	category,
	subcategory,
	cost
)
SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sales_date,
	DATEDIFF(MONTH, last_sales_date, GETDATE()) AS recency_in_months,
	life_span_in_months,
	total_sales,
	total_customers,
	CASE 
		WHEN total_sales > 50000 THEN 'High-Performer'
		WHEN total_sales >= 10000 THEN 'Mid-Range'
		ELSE 'Low-Performer' 
	END AS product_segment,	
	total_orders,
	total_quantity,
	average_selling_price,
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE total_sales/total_orders 
	END AS average_order_revenue,
	CASE 
		WHEN life_span_in_months = 0 THEN total_sales
		ELSE total_sales/life_span_in_months 
	END AS average_monthly_revenue	
FROM product_aggregation



SELECT 
age_group, 
COUNT(customer_number) as total_customers,
SUM(total_sales) AS total_sales
FROM gold.customer_report
GROUP BY age_group;

SELECT 
customer_segment, 
COUNT(customer_number) as total_customers,
SUM(total_sales) AS total_sales
FROM gold.customer_report
GROUP BY customer_segment;



CREATE VIEW gold.Cum_sales_mov_avg_price AS(
SELECT order_year,
total_sales,
SUM(total_sales) OVER (ORDER BY order_year) AS running_total_sales, --Distinct cumulative sum for each year--
AVG(avg_price) OVER (ORDER BY order_year) AS moving_average_price --Distinct cumulative sum for each year--
FROM
(select 
YEAR(order_date) as order_year,
SUM(sales_amount) as total_sales,
AVG(price) as avg_price
from gold.fact_sales
where order_date is not null
group by YEAR(order_date)
)t)



----------Total sales Amount & Quantities Sold by Cost Range-------
SELECT
CASE WHEN p.cost < 100 THEN 'Below 100'
	 WHEN p.cost BETWEEN 100 AND 500 THEN '100-500'
	 WHEN p.cost BETWEEN 500 AND 1000 THEN '500-1000'
	 ELSE 'Above 1000'
END cost_range,
SUM(sales_amount) AS total_sales,
SUM(s.quantity) total_quantity
FROM gold.dim_products p
LEFT JOIN  gold.fact_sales s
ON p.product_key = s.product_key
WHERE s.order_date is not null
GROUP BY 
CASE WHEN p.cost < 100 THEN 'Below 100'
	 WHEN p.cost BETWEEN 100 AND 500 THEN '100-500'
	 WHEN p.cost BETWEEN 500 AND 1000 THEN '500-1000'
	 ELSE 'Above 1000'
END 

---------Average Monthly Rrevenue By Product Segment and Subcategory------
SELECT 
	subcategory,
	product_segment,
SUM(average_monthly_revenue) average_monthly_revenue
FROM gold.product_report
GROUP BY 
	subcategory,
	product_segment
ORDER BY average_monthly_revenue desc;

