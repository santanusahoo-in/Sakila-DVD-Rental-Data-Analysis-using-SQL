-- Select the Sakila database
USE sakila;

-- Verify that the main tables exist
SHOW TABLES;

-- Table Creation
CREATE OR REPLACE VIEW v_payment_analysis AS
SELECT 
    p.payment_id,
    p.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.store_id,
    p.amount AS payment_amount,
    p.payment_date,
    r.rental_date,
    r.return_date,
    f.film_id,
    f.title AS film_title,
    f.rental_duration,
    f.rental_rate,
    cat.name AS category_name
FROM payment p
JOIN rental r         ON p.rental_id = r.rental_id
JOIN inventory i      ON r.inventory_id = i.inventory_id
JOIN film f           ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category cat     ON fc.category_id = cat.category_id
JOIN customer c       ON p.customer_id = c.customer_id;

-- Data Exploration & Cleaning
-- Check total rows in main tables
SELECT 'film' AS table_name, COUNT(*) AS total_rows FROM film
UNION ALL
SELECT 'rental', COUNT(*) FROM rental
UNION ALL
SELECT 'payment', COUNT(*) FROM payment
UNION ALL
SELECT 'customer', COUNT(*) FROM customer;

-- Look at first few rows in each table
SELECT * FROM film LIMIT 5;
SELECT * FROM rental LIMIT 5;
SELECT * FROM payment LIMIT 5;
SELECT * FROM customer LIMIT 5;

-- Check for missing values in rental and payment tables
SELECT 
  SUM(CASE WHEN rental_date IS NULL THEN 1 ELSE 0 END) AS missing_rental_date,
  SUM(CASE WHEN return_date IS NULL THEN 1 ELSE 0 END) AS missing_return_date
FROM rental;

SELECT 
  SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END) AS missing_payment_amount
FROM payment;

-- Check for duplicate rentals
SELECT rental_id, COUNT(*) AS count
FROM rental
GROUP BY rental_id
HAVING COUNT(*) > 1;

-- Data Cleaning
CREATE OR REPLACE VIEW v_rental_clean AS
SELECT 
    r.rental_id,
    r.customer_id,
    r.inventory_id,
    r.rental_date,
    r.return_date,
    TIMESTAMPDIFF(HOUR, r.rental_date, r.return_date) AS rental_hours
FROM rental r;

-- Data Analysis & Findings
-- Revenue by Film Category:This query shows which movie categories bring in the most revenue.
SELECT 
    category_name,
    ROUND(SUM(payment_amount), 2) AS total_revenue
FROM v_payment_analysis
GROUP BY category_name
ORDER BY total_revenue DESC;

-- Monthly Revenue Trend: This query helps to understand revenue changes over time.
SELECT 
    DATE_FORMAT(payment_date, '%Y-%m') AS month,
    ROUND(SUM(payment_amount), 2) AS monthly_revenue
FROM v_payment_analysis
GROUP BY month
ORDER BY month;

-- Store Performance: Find out which store performs better based on revenue and customers.
SELECT 
    store_id,
    ROUND(SUM(payment_amount), 2) AS total_revenue,
    COUNT(DISTINCT customer_id) AS total_customers
FROM v_payment_analysis
GROUP BY store_id
ORDER BY total_revenue DESC;

-- Top Customers by Spending (LTV): Find the customers who spend the most overall.
SELECT 
    customer_id,
    customer_name,
    ROUND(SUM(payment_amount), 2) AS total_spent,
    COUNT(payment_id) AS total_transactions
FROM v_payment_analysis
GROUP BY customer_id, customer_name
ORDER BY total_spent DESC
LIMIT 10;

-- Most Rented Movies (Top Films): Find which movies are rented the most times.
SELECT 
    film_title,
    COUNT(*) AS total_rentals
FROM v_payment_analysis
GROUP BY film_title
ORDER BY total_rentals DESC
LIMIT 10;

-- Inactive Customers (Churn): Find customers who haven’t rented a movie in the last 90 days.
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    MAX(r.rental_date) AS last_rental_date
FROM customer c
LEFT JOIN rental r ON c.customer_id = r.customer_id
GROUP BY c.customer_id, customer_name
HAVING last_rental_date < DATE_SUB(CURDATE(), INTERVAL 90 DAY)
   OR last_rental_date IS NULL
ORDER BY last_rental_date;
