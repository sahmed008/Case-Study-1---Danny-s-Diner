--https://8weeksqlchallenge.com/case-study-1/


CREATE TABLE sales (
"customer_id" NVARCHAR(1),
"order_date" DATE,
"product_id" INTEGER
);

INSERT INTO sales
	(customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');

CREATE TABLE menu (
	"product_id" INTEGER,
	"product_name" NVARCHAR(5),
	"price" INTEGER
);

INSERT INTO menu
	(product_id, product_name, price)
VALUES
	('1', 'sushi', '10'),
	('2', 'curry', '15'),
	('3', 'ramen', '12');


CREATE TABLE members (
	"customer_id" NVARCHAR(1),
	"join_date" DATE
);

INSERT INTO members
	(customer_id, join_date)
VALUES
	('A', '2021-01-07'),
	('B', '2021-01-09');


SELECT * FROM members;
SELECT * FROM sales;
SELECT * FROM menu;


-- CASE STUDY QUESTIONS
-- 1. What is the total amount each customer spent at the restaurant? 

SELECT 
	customer_id,
	SUM(price) AS total_amount_spent
FROM SALES s
INNER JOIN menu m
	ON s.product_id = m.product_id
GROUP BY customer_id;

--2. How many days has each customer visited the restaurant?

SELECT 
	customer_id, 
	COUNT(DISTINCT(order_date)) as customer_visit
FROM sales
GROUP BY customer_id
ORDER BY customer_visit DESC;

--3. What was the first item from the menu purchased by each customer?

WITH cte_first_sales AS (
SELECT 
	customer_id,
	order_date, 
	product_name,	
				DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
FROM sales s
INNER JOIN menu m
	ON s.product_id = m.product_id
)

SELECT 
  customer_id, 
  product_name
FROM cte_first_sales
WHERE rank = 1
GROUP BY customer_id, product_name;


--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
	product_name, 
	COUNT(s.product_id) as times_ordered
from sales s
LEFT JOIN menu m
	ON
	s.product_id = m.product_id
GROUP BY product_name
ORDER BY 2 DESC;

--5. Which item was the most popular for each customer?

WITH cte_popular_items AS (
SELECT 
	s.customer_id,
	m.product_name,
	COUNT(s.product_id) AS order_count,
				DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.customer_id) DESC) AS rank
FROM sales s
INNER JOIN menu m
	ON
	s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name
)

SELECT 
	customer_id,
	product_name,
	order_count
FROM cte_popular_items
WHERE rank = 1;


--6. Which item was purchased first by the customer after they became a member?
WITH cte_member_sales AS 
(
SELECT 
	s.customer_id,
	join_date,
	order_date,
	product_id,
	DENSE_RANK () OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
FROM sales s
INNER JOIN members m
	ON s.customer_id = m.customer_id
WHERE order_date >= join_date
)
	
SELECT 
	customer_id, 
	order_date, 
	product_name
FROM cte_member_sales
INNER JOIN menu m2
	ON cte_member_sales.product_id = m2.product_id
WHERE rank = 1;

--------------
--7. Which item was purchased just before the customer became a member?

WITH cte_prior_member_sales AS 
(
SELECT 
	s.customer_id,
	join_date,
	order_date,
	product_id,
	DENSE_RANK () OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rank
FROM sales s
INNER JOIN members m
	ON s.customer_id = m.customer_id
WHERE order_date < join_date
)
	
SELECT 
	customer_id, 
	order_date, 
	product_name
FROM cte_prior_member_sales
INNER JOIN menu m2
	ON cte_prior_member_sales.product_id = m2.product_id
WHERE rank = 1;

-------------------------------------

--8. What is the total items and amount spent for each member before they became a member?

SELECT 
	s.customer_id, COUNT(DISTINCT(s.product_id)) AS order_count, SUM(m2.price) AS amount_spent
FROM members m1
INNER JOIN sales s
	ON s.customer_id = m1.customer_id
INNER JOIN menu m2
	ON s.product_id = m2.product_id
WHERE s.order_date < m1.join_date
GROUP BY s.customer_id;

------------------

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH cte_price_point AS
(
	SELECT *, 
		CASE WHEN product_name = 'sushi' THEN price * 20
		ELSE price * 10 END AS points
	FROM menu
)

SELECT 
	s.customer_id, 
	SUM(p.points) AS total_points
FROM cte_price_point AS p
INNER JOIN sales s
	ON s.product_id = p.product_id
GROUP BY s.customer_id

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
-- 1. Find member validity date of each customer and get last date of January
-- 2. Use CASE WHEN to allocate points by date and product id
-- 3. SUM price and points

WITH dates_cte AS
(
	SELECT 
    *, 
    DATEADD(DAY, 6, join_date) AS valid_date, 
		EOMONTH(join_date) AS last_date
	FROM members AS m
)

SELECT 
  d.customer_id, 
  s.order_date, 
  d.join_date, 
  d.valid_date, 
  d.last_date, 
  m.product_name, 
  m.price,
	SUM( 
    CASE WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
		WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN 2 * 10 * m.price
		ELSE 10 * m.price END) AS points
FROM dates_cte AS d
JOIN sales AS s
	ON d.customer_id = s.customer_id
JOIN menu AS m
	ON s.product_id = m.product_id
WHERE s.order_date < d.last_date
GROUP BY d.customer_id, s.order_date, d.join_date, d.valid_date, d.last_date, m.product_name, m.price;

-- Join All The Things
-- Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)

SELECT 
	s.customer_id,
	order_date,
	product_name,
	price,
		CASE WHEN order_date < join_date THEN 'N'
		WHEN join_date <= order_date THEN 'Y'
		ELSE 'N' END AS member
FROM sales s
LEFT JOIN menu m
ON s.product_id = m.product_id
LEFT JOIN members m2
ON m2.customer_id = s.customer_id
ORDER BY s.customer_id, s.order_date;
-------------------------------------------------------------------------------------------------------------------------------------------------
-- Rank All The Things
-- Recreate the table with: customer_id, order_date, product_name, price, member (Y/N), ranking(null/123)

WITH cte_ranking AS
(	SELECT 
		s.customer_id,
		order_date,
		product_name,
		price,
			CASE WHEN order_date < join_date THEN 'N'
			WHEN order_date >= join_date THEN 'Y'
			ELSE 'N' END as member
	FROM sales s
	LEFT JOIN menu m
		ON s.product_id = m.product_id
	LEFT JOIN members m2
		ON m2.customer_id = s.customer_id
)


SELECT 
	*,
	CASE WHEN member = 'N' THEN NULL
	ELSE	
		RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date)
	END AS ranking
FROM cte_ranking; 

------------------------------------------------------------------------------------------------





