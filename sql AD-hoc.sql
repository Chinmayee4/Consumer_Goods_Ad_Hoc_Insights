-- Q1.1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT DISTINCT(market) FROM dim_customer
WHERE customer='Atliq Exclusive'
AND region ='APAC';

-- Q2.What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg
WITH unique_product_count AS(
SELECT 
COUNT(DISTINCT CASE WHEN fiscal_year=2020 THEN product_code END)AS unique_products_2020,
COUNT(DISTINCT CASE WHEN fiscal_year=2021 THEN product_code END)AS unique_products_2021
FROM fact_sales_monthly
WHERE fiscal_year IN (2020,2021)
)
SELECT unique_products_2020,unique_products_2021,
ROUND((unique_products_2021-unique_products_2020)*100/unique_products_2020,2) AS percentage_chg
FROM unique_product_count;

-- Q3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields, segment product_count
SELECT segment,
COUNT(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- Q4.Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, segment product_count_2020 product_count_2021 difference
WITH unique_product AS(
SELECT b.segment AS segment,
COUNT(DISTINCT(CASE WHEN fiscal_year=2020 THEN a.product_code END)) AS product_count_2020,
COUNT(DISTINCT(CASE WHEN fiscal_year=2021 THEN a.product_code END)) AS product_count_2021
FROM fact_sales_monthly AS a
JOIN dim_product AS b
ON a.product_code=b.product_code
WHERE fiscal_year IN (2020,2021)
GROUP BY b.segment
)
SELECT segment,product_count_2020,product_count_2021,
(product_count_2021-product_count_2020) AS difference
FROM unique_product;

-- Q5.Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, product_code product manufacturing_cost
SELECT a.product_code AS product_code,
a.product AS product,b.manufacturing_cost AS manufacturing_cost
FROM 
dim_product a
INNER JOIN 
fact_manufacturing_cost b
ON a.product_code=b.product_code
WHERE b.manufacturing_cost IN 
(
SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost
UNION
SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost);

-- Q6.Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. The final output contains these fields, customer_code customer average_discount_percentage

SELECT a.customer_code,b.customer,
   CONCAT(ROUND(AVG(a.pre_invoice_discount_pct)*100,2),'%') AS average_discount_percentage
FROM 
fact_pre_invoice_deductions AS a
INNER JOIN 
dim_customer AS b
ON a.customer_code=b.customer_code
WHERE market='India'
AND fiscal_year=2021
GROUP BY customer,customer_code
ORDER BY AVG(a.pre_invoice_discount_pct) DESC
LIMIT 5;

-- Q7.Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . This analysis helps to get an idea of low and high-performing months and take strategic decisions. The final report contains these columns: Month Year Gross sales Amount
SELECT 
     CONCAT(MONTHNAME(a.date),' ',YEAR(a.date)) AS month,
     a.fiscal_year,
     ROUND(SUM(a.sold_quantity*b.gross_price),2) AS gross_sales_amount
FROM  fact_sales_monthly AS a
INNER JOIN fact_gross_price AS b
ON b.product_code=a.product_code
AND b.fiscal_year=a.fiscal_year
INNER JOIN dim_customer AS c
ON c.customer_code=a.customer_code
WHERE c.customer='Atliq Exclusive'
GROUP BY month , a.fiscal_year
ORDER BY a.fiscal_year;

-- Q8.In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity
SELECT
  CASE
      WHEN MONTH(date) IN (9,10,11) THEN 'Q1'
      WHEN MONTH(date) IN (12,1,2) THEN 'Q2'
      WHEN MONTH(date) IN (3,4,5) THEN 'Q3'
   ELSE 'Q4'
   END AS quarters,
   SUM(sold_quantity) AS total_sold_quantity
   FROM fact_sales_monthly
   WHERE fiscal_year=2020
   GROUP BY quarters
   ORDER BY total_sold_quantity DESC;
   
   -- Q9.Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields, channel gross_sales_mln percentage
   WITH gross_sales AS(
   SELECT
        c.channel AS channel,
        ROUND(SUM(b.gross_price*a.sold_quantity)/1000000,2) AS gross_sales_min
    FROM fact_sales_monthly AS a
    LEFT JOIN fact_gross_price AS b
    ON a.product_code=b.product_code
    AND a.fiscal_year=b.fiscal_year
    LEFT JOIN dim_customer AS c
    ON a.customer_code=c.customer_code
    WHERE a.fiscal_year=2021
    GROUP BY c.channel
    )
    SELECT channel,
    CONCAT('$',gross_sales_min) AS gross_sales_min,
    CONCAT(ROUND(gross_sales_min*100/SUM(gross_sales_min) OVER(),2),'%') AS percentage
    FROM gross_sales
    ORDER BY percentage DESC;
    
    -- Q10.10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields, division product_code product total_sold_quantity rank_order.
    WITH top_sold_products AS(
    SELECT b.division AS division,
    b.product_code AS product_code,
    b.product AS product,
    SUM(a.sold_quantity) AS total_sold_quantity
    FROM fact_sales_monthly AS a
    INNER JOIN dim_product AS b
    ON a.product_code=b.product_code
    WHERE a.fiscal_year=2021
    GROUP BY b.division,b.product_code,b.product
    ORDER BY total_sold_quantity DESC
    ),
    top_sold_per_division AS
    (
    SELECT division,product_code,product,total_sold_quantity,
    DENSE_RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
    FROM top_sold_products
    )
    SELECT * FROM top_sold_per_division
    WHERE rank_order <=3; 
  