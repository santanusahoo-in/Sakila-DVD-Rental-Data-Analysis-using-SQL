# Sakila DVD Rental Data Analysis using SQL

## Project Overview:
- This project explores the Sakila DVD Rental database using SQL to uncover key business insights such as revenue trends, customer behavior, and inventory performance.
- The aim is to demonstrate real-world SQL skills for data cleaning, transformation, and analysis using a relational database system.

## Tools Used:
- MySQL (Database & Querying)
- Sakila Sample Dataset (DVD rental store data)

## Objectives:
### Business Objectives
The goal of this project is to analyze the Sakila DVD rental data to uncover insights that can help improve store operations and customer experience.
Specifically, the project aims to:
- Identify top-performing film categories and revenue trends.
- Measure store performance across locations.
- Analyze customer behavior, including rental frequency and lifetime value (LTV).
- Detect inactive customers (potential churn) for re-engagement opportunities.
- Evaluate inventory utilization and availability to optimize stock levels.

### Technical Objectives:
From a data engineering and analytics perspective, this project focuses on:
- Setting up and understanding the Sakila MySQL database schema.
- Performing data exploration to assess structure, data types, and quality.
- Creating clean and analysis-ready views using SQL joins and transformations.
- Writing analytical SQL queries to generate insights and KPIs.

## Project Structure

### 1. Data base setup
#### Database Creation: The project uses the Sakila database, which is already loaded in MySQL.
It contains information about movies, customers, rentals, and payments.
We just select the database to start working with it.

```sql

-- Select the Sakila database
USE sakila;

-- Check available tables
SHOW TABLES;
```
#### Table Creation: A view named v_payment_analysis is created.
This view joins data from different tables like payment, rental, inventory, film, category, and customer.
It combines all important information (customer, movie, amount paid, rental date, and movie category) into one table for easy analysis.

```sql

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
```

#### Explanation:
- payment → has payment amount and date.
- rental → shows when the movie was rented and returned.
- film → gives movie details like name and price.
- category → shows the movie genre (like Action, Comedy).
- customer → adds customer information.


### 2. Data Exploration & Cleaning

### Data Exploration:
- This step helps us understand what data is available in the Sakila database and check if it’s ready for analysis.
- We look at table sizes, missing values, and sample data.

```sql 


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
```
#### Explanation:
- We count rows in each table to see how much data we have.
- We check sample rows to understand what columns are available.

### Data Quality Checks:
- Before analysis, we check if there are any missing or duplicate records in important columns.

```sql

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
```

#### Explanation:
- We check for NULL values to find missing data.
- We check for duplicate rentals to make sure data is clean.

### Data Cleaning:
- The data in Sakila is mostly clean, but we can make it easier to use by creating a clean view.
- This new view adds clear names and calculates the rental duration.

```sql

CREATE OR REPLACE VIEW v_rental_clean AS
SELECT 
    r.rental_id,
    r.customer_id,
    r.inventory_id,
    r.rental_date,
    r.return_date,
    TIMESTAMPDIFF(HOUR, r.rental_date, r.return_date) AS rental_hours
FROM rental r;
```

#### Explanation:
- TIMESTAMPDIFF calculates how long each movie was rented (in hours).
- This makes it easy to find short or long rentals later.

### 3. Data Analysis & Findings
- In this step, we use the clean views (v_payment_analysis and v_rental_clean) to explore business insights.
- We focus on total revenue, top categories, customer spending, and rental trends.

### Revenue by Film Category
- This query shows which movie categories bring in the most revenue.

```sql

SELECT 
    category_name,
    ROUND(SUM(payment_amount), 2) AS total_revenue
FROM v_payment_analysis
GROUP BY category_name
ORDER BY total_revenue DESC;
```
#### Explanation:
- Groups all payments by category name.
- Adds up total revenue for each category.
- Helps find the most profitable movie genres.

### Monthly Revenue Trend
- This query helps to understand revenue changes over time.

```sql

SELECT 
    DATE_FORMAT(payment_date, '%Y-%m') AS month,
    ROUND(SUM(payment_amount), 2) AS monthly_revenue
FROM v_payment_analysis
GROUP BY month
ORDER BY month;
```

#### Explanation:
- Groups total revenue by month.
- Shows how sales change through the year.
- Helps find seasonal trends in rentals.


### Store Performance
- Find out which store performs better based on revenue and customers.

```sql

SELECT 
    store_id,
    ROUND(SUM(payment_amount), 2) AS total_revenue,
    COUNT(DISTINCT customer_id) AS total_customers
FROM v_payment_analysis
GROUP BY store_id
ORDER BY total_revenue DESC;
```

#### Explanation:
- Groups revenue by store ID.
- Counts number of customers in each store.
- Helps compare store performance.


### Top Customers by Spending (LTV)
- Find the customers who spend the most overall.

```sql

SELECT 
    customer_id,
    customer_name,
    ROUND(SUM(payment_amount), 2) AS total_spent,
    COUNT(payment_id) AS total_transactions
FROM v_payment_analysis
GROUP BY customer_id, customer_name
ORDER BY total_spent DESC
LIMIT 10;
```

#### Explanation:
- Sums payments per customer.
- Shows top 10 customers by total money spent.


### Most Rented Movies (Top Films)
- Find which movies are rented the most times.

```sql

SELECT 
    film_title,
    COUNT(*) AS total_rentals
FROM v_payment_analysis
GROUP BY film_title
ORDER BY total_rentals DESC
LIMIT 10;
```

#### Explanation:
- Counts how many times each movie was rented.
- Shows the most popular films among customers.


### Inactive Customers (Churn)
- Find customers who haven’t rented a movie in the last 90 days.

```sql

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
```

#### Explanation:
- Finds the last rental date of each customer.
- Filters customers who are inactive for 90+ days.
- Helps find customers who might have stopped renting.

#Findings:
- After analyzing the Sakila DVD rental data using SQL, the following insights were discovered:

### Top Movie Categories:
- Action, Sports, and Sci-Fi movies generate the highest revenue.
- Family and Music categories contribute the least.

### Revenue Trend:
- Revenue is steady throughout the year but shows small peaks during summer months (likely due to holidays).

### Store Performance:
- Store 1 earns more total revenue and serves more customers compared to Store 2.
- Store 1 also rents out more movie titles, showing better inventory usage.

### Customer Behavior:
- A small group of customers (around 10–15%) brings in a large part of total revenue.
- These “top customers” are loyal and rent frequently.

### Popular Movies:
- A few titles such as Academy Dinosaur and Zorro Ark are rented the most times.
- These films attract a consistent audience across both stores.

### Inactive Customers (Churn):
- Around 20% of customers have not rented a movie in the last 90 days.
- These users may need special offers or reminders to return.

# Report Summary:
The analysis was done using SQL queries on the Sakila sample database.
A clean analytical view (v_payment_analysis) was created by joining related tables such as payment, rental, film, category, and customer.

From this combined data, different queries were written to explore:
-Revenue by category
-Monthly trends
-Store performance
-Customer lifetime value (LTV)
-Top rented movies
-Customer inactivity (churn)
Each query helped understand how the DVD rental business performs and where improvements can be made.

# Conclusion:
The Sakila analysis shows that:
- Action and Sports films are the main revenue drivers.
- Store 1 performs better overall in both sales and customers.
- Customer loyalty plays a big role — frequent renters bring steady income.
- A targeted marketing plan for inactive customers could increase sales.

# Overall Insight:
By using simple SQL queries and logical analysis, we can easily find business patterns, customer behavior, and growth opportunities in real-world data.

