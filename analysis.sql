#CASe Study QuestiONs
#Each of the following cASe study questiONs can be answered using a single SQL statement
use dannys_diner;
SELECT * FROM sales;
SELECT * FROM menu;
SELECT * FROM members;


-- Ques 1 What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, sum(m.price) AS total_amount
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;


-- Ques 2 How many days hAS each customer visited the restaurant?
SELECT * FROM sales;
SELECT customer_id, count(distinct order_date) visits
FROM sales
GROUP BY customer_id;


-- Ques 3 What wAS the first item FROM the menu purchASed by each customer?
SELECT customer_id, product_name
FROM (SELECT customer_id, product_name, 
ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) row_num
FROM sales s 
INNER JOIN menu m ON s.product_id = m.product_id) t
WHERE row_num = 1;


-- Ques 4 What is the most purchASed item ON the menu and how many times wAS it purchASed by all customers?
SELECT product_name, orders
FROM (
    SELECT product_name, COUNT(*) AS orders
    FROM sales s
    INNER JOIN menu m 
        ON s.product_id = m.product_id
    GROUP BY product_name
) t
ORDER BY orders DESC
LIMIT 1;


-- Ques 5 Which item wAS the most popular for each customer?
WITH item_count AS (SELECT customer_id, product_name, 
count(*) order_count,
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY count(*) DESC) AS rnk
FROM sales s 
JOIN menu m 
ON s.product_id = m.product_id
GROUP BY customer_id, product_name)

SELECT customer_id, product_name
FROM item_count
WHERE rnk = 1;


-- Ques 6 Which item wAS purchASed first by the customer after they became a member?
WITH after_member AS (SELECT s.customer_id, m.product_name, s.order_date, me.join_date,
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) row_num
FROM sales s 
LEFT JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members me ON s.customer_id = me.customer_id 
WHERE s.order_date >= me.join_date)

SELECT customer_id, product_name FROM after_member
WHERE row_num =1;


-- Ques 7 Which item was purchASed just before the customer became a member?
WITH before_member AS (SELECT s.customer_id, m.product_name, s.order_date, me.join_date,
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date desc) row_num
FROM sales s 
LEFT JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members me ON s.customer_id = me.customer_id 
WHERE s.order_date < me.join_date)

SELECT customer_id, product_name FROM before_member
WHERE row_num =1;

-- Ques 8 What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, 
s.order_date,
me.join_date,
count(s.product_id) AS total_items_ordered,
sum(m.price) AS total_price
FROM sales s 
LEFT JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members me ON s.customer_id = me.customer_id
WHERE s.order_date < me.join_date
GROUP BY s.customer_id, s.order_date,
me.join_date;


-- Ques 9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with cte as (SELECT s.customer_id, m.product_name, m.price,
CASE WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
ELSE m.price * 10
END as points
FROM sales s
LEFT JOIN menu m on s.product_id = m.product_id)

SELECT customer_id, sum(points) 
FROM cte 
GROUP BY customer_id;


-- Ques 10 In the first week after a customer joins the program (including their join date) they earn 2x points ON all items, not just sushi - how many points do customer A and B have at the end of January?
with cte as (SELECT s.customer_id, m.product_name, m.price, order_date, join_date,
CASE
	WHEN order_date BETWEEN me.join_date AND date_add(me.join_date, interval 7 day) then m.price*10*2
    WHEN m.product_name = 'sushi' then m.price *10*2
    ELSE m.price*10
    END as points
FROM sales s
JOIN menu m 
ON s.product_id = m.product_id
JOIN members me
ON s.customer_id = me.customer_id
WHERE order_date <= "2021-01-31" 
ORDER BY s.customer_id,  s.order_date)

SELECT customer_id, sum(points) 
FROM cte
GROUP BY customer_id
ORDER BY customer_id;
