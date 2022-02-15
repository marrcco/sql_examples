/* Identify duplicate records */
SELECT 'iid', order_number, COUNT(*) FROM order_data GROUP BY 'iid', order number HAVING COUNT(*) > 1; 

/* Create new table without duplicates */
CREATE TABLE order_data_no_duplicates AS SELECT DISTINCT * FROM order_data;

/* transform JSON data from order_data table */
CREATE TABLE transformed_order_data (
	SELECT 'iid', order_number, order_revision, CAST(SUBSTRING(order_created_at_utc,1,10) AS DATE) AS order_date,
	sub_total_amount, tax_total_amount, shipping_total_amount, fee_total_amount, order_total_amount, requires_payment,
	charge_refunded, refunded_at_utc, customer_id, age, gender, income, group_id, group_name, customer_state, customer_country,
	JSON_EXTRACT(orderlineitems_jsonb, '$[0].productVariantId') AS product_variant_id,
	JSON_EXTRACT(orderlineitems_jsonb, '$[0].price.amount') AS product_price,
	JSON_EXTRACT(orderlineitems_jsonb, '$[0].price.currency') AS product_price_currency
	FROM order_data_no_duplicates
);
	
/* Create a new column to sequentially rank the order withing each customer by chronological ORDER */
SELECT customer_id, gender, CAST(SUBSTRING(order_created_at_utc, 1, 10) AS DATE) AS order_date,
DENSE_RANK () OVER (PARTITION BY customer_id ORDER BY order_created_at_utc DESC) AS order_rank
FROM order_data_no_duplicates
ORDER BY order_rank DESC;

/* Find out which group has the most members */
SELECT COUNT(DISTINCT(customer_id)) AS num_of_members, group_name
FROM transformed_order_data
GROUP BY 2
HAVING LENGTH (group_name) > 0
ORDER BY 1 DESC
LIMIT 1;

/* Number of orders by country/state */
SELECT customer_country, COUNT(customer_country)
FROM transformed_order_data
GROUP BY 1
ORDER BY COUNT(1) DESC;

/* Total Revenue in NY per month */
SELECT MONTH(order_date) AS 'month', customer_state, SUM(order_total_amount) AS revenue
FROM transformed_order_data
GROUP BY MONTH(order_date), customer_state
HAVING customer_state = 'NY';


