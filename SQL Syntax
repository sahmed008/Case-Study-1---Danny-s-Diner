--------------------------------
--CASE STUDY #1: DANNY'S DINER--
--------------------------------

CREATE SCHEMA dannys_diner;

CREATE TABLE dannys_diner.sales (
	customer_id NVARCHAR(1),
	order_date DATE,
	product_id INTEGER
);


INSERT INTO dannys_diner.sales
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
 

 CREATE TABLE dannys_diner.menu (
	product_id INTEGER,
	product_name NVARCHAR(5),
	price INTEGER
);


INSERT INTO dannys_diner.menu (
product_id, product_name, price)
VALUES
	 ('1', 'sushi', '10'),
	('2', 'curry', '15'),
	('3', 'ramen', '12');



CREATE TABLE dannys_diner.members (
  "customer_id" NVARCHAR(1),
  "join_date" DATE
);

INSERT INTO dannys_diner.members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


SELECT * FROM dannys_diner.sales;
SELECT * FROM dannys_diner.members;
SELECT * FROM dannys_diner.menu;

-- CASE STUDY QUESTIONS

--1. What is the total amount each customer spent at the restaurant?

SELECT 
	s.customer_id, SUM(m.price) AS price
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY price DESC;


--2. How many days has each customer visited the restaurant?

SELECT 
	customer_id, SUM(DAY(order_date)) AS customer_visits
FROM dannys_diner.sales
GROUP BY customer_id;


-- 3. What was the first item from the menu purchased by each customer?

WITH cte_rnk AS (
SELECT 
	*,
	DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS rnk
FROM dannys_diner.sales
)

SELECT 
	customer_id, order_date, product_id 
FROM cte_rnk
WHERE rnk = 1;


SELECT * FROM dannys_diner.sales;

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
	menu.product_name, COUNT(sales.product_id) as order_count	
FROM dannys_diner.sales AS sales
INNER JOIN dannys_diner.menu AS menu
ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY order_count DESC;

-- 5. Which item was the most popular for each customer?

WITH cte_popular AS (
SELECT
	sales.customer_id, 
	menu.product_name, 
	COUNT(sales.product_id) AS order_count,
	DENSE_RANK() OVER (PARTITION BY sales.customer_id ORDER BY COUNT(sales.customer_id) DESC) AS rank
FROM dannys_diner.sales AS sales
INNER JOIN dannys_diner.menu AS menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id, menu.product_name
)
SELECT 
	customer_id,
	product_name,
	order_count
FROM cte_popular
WHERE rank = 1;


-- 6. Which item was purchased first by the customer after they became a member?

WITH cte_member_orders AS (
SELECT 
	s.customer_id,
	s.order_date,
	s.product_id,
	mm.join_date,
	DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date) AS rank	
FROM dannys_diner.members mm
INNER JOIN dannys_diner.sales s
ON s.customer_id = mm.customer_id
WHERE s.order_date >= mm.join_date
)

SELECT 
	m1.customer_id,
	m1.order_date,
	m2.product_name
FROM cte_member_orders AS m1
INNER JOIN dannys_diner.menu AS m2
ON m1.product_id = m2.product_id
WHERE rank = 1;


--7. Which item was purchased just before the customer became a member?

WITH cte_before_membership AS (
SELECT
	s.customer_id,
	s.order_date,
	s.product_id,
	m1.join_date,
	m2.product_name,
	DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
FROM dannys_diner.members AS m1
INNER JOIN dannys_diner.sales AS s
ON m1.customer_id = s.customer_id
INNER JOIN dannys_diner.menu AS m2
ON s.product_id = m2.product_id
WHERE s.order_date < m1.join_date
)

SELECT 
	customer_id,
	product_name,
	order_date
FROM cte_before_membership
WHERE rank = 1;


-- 8. What is the total items and amount spent for each member before they became a member?

WITH cte_before_membership AS (
SELECT
	s.customer_id,
	s.product_id,
	m2.price
FROM dannys_diner.members AS m1
INNER JOIN dannys_diner.sales AS s
ON m1.customer_id = s.customer_id
INNER JOIN dannys_diner.menu AS m2
ON s.product_id = m2.product_id
WHERE s.order_date < m1.join_date
)

SELECT 
	customer_id,
	COUNT(DISTINCT product_id) as total_items,
	SUM(price) AS total_spent
FROM cte_before_membership
GROUP BY customer_id;


--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH cte_point AS (
SELECT
	s.customer_id,
	mm.product_name,
	SUM(mm.price) AS total_spent
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS mm
ON mm.product_id = s.product_id
GROUP BY customer_id, product_name
)

SELECT
	customer_id,
	SUM(CASE WHEN product_name = 'sushi' THEN total_spent * 10 * 2
	ELSE total_spent * 10
	END ) AS total_points
FROM cte_point
GROUP BY customer_id;



--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH cte_dates AS
( SELECT
		*,
		DATEADD(DAY, 6, join_date) AS valid_date,
			EOMONTH('2021-01-31') AS last_date
	FROM dannys_diner.members AS m
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
			CASE WHEN m.product_name = 'sushi' THEN 2*10*m.price
				WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN 2*10*m.price
				ELSE 10*m.price END) AS points
	FROM cte_dates AS d
	INNER JOIN dannys_diner.sales AS s
		ON s.customer_id = d.customer_id
	INNER JOIN dannys_diner.menu AS m
		ON s.product_id = m.product_id
	WHERE s.order_date < d.last_date
	GROUP BY  d.customer_id, s.order_date, d.join_date, d.valid_date, d.last_date, m.product_name, m.price;


--BONUS QUESTIONS

SELECT
	s.customer_id,
	s.order_date,
	m2.product_name,
	m2.price,
	(CASE WHEN s.order_date >= m1.join_date THEN 'Y'
	ELSE 'N'
	END) AS member
FROM dannys_diner.members AS m1
RIGHT JOIN dannys_diner.sales AS s
ON m1.customer_id = s.customer_id
LEFT JOIN dannys_diner.menu AS m2
ON m2.product_id = s.product_id


----------------------------------------------------------------
WITH cte_ranking AS (
SELECT
	s.customer_id,
	s.order_date,
	m2.product_name,
	m2.price,
	(CASE WHEN s.order_date >= m1.join_date THEN 'Y'
	ELSE 'N'
	END) AS member
FROM dannys_diner.members AS m1
RIGHT JOIN dannys_diner.sales AS s
ON m1.customer_id = s.customer_id
LEFT JOIN dannys_diner.menu AS m2
ON m2.product_id = s.product_id
)
SELECT 
	*,
	CASE WHEN member = 'N' THEN NULL
	ELSE
		RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date) 
		END AS ranking
FROM cte_ranking
ORDER BY customer_id, order_date;











