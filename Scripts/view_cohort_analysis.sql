/* Requirement 1 : Create a cohort analysis view to analyze customer purchasing behavior over time by creating cohort groups of customerkeys and their orderdates, and also find out their corresponding first_purchase_date and cohort_year corresponding to their customerkey of each cohort group:-
	- For this we will first create a CTE called customer_revenue where we will aggregate the sales data for each cohort groups ofcustomer and orderdate. 
	- We will also call in the extra information from the customer table(by left joining them) for each customer & orderdate cohort group, for which we will also need to add the columns in the GROUP BY clause since we have made use of aggregation functions in the SELECT clause.
	- Once the CTE is created in the main query we will also find each customer's and their orderdate's corresponding first_purchase_date and cohort_year.(using OVER() function AND PARTITION BY sub-clause).
	- After checking the results, we will create a view named cohort_analysis out of the query. */

CREATE OR REPLACE VIEW cohort_analysis AS -- will create a view of the query below which will in a cr CTE's result-set will find the customer and orderdate wise aggregation result , with customer additional info from c table, and finally will retrieve the customerkey, its corresponding first_purchase_date and cohort_year.
WITH customer_revenue AS ( -- the CTE's result set will retrieve the customer-wise aggregation results for each orderdate for that customer, and additional info about customer from customer table.
SELECT 
	s.customerkey,
	s.orderdate,
	SUM(s.netprice * s.quantity * s.exchangerate) AS total_net_revenue,
	COUNT(s.orderkey) AS num_order,
	c.countryfull,
	c.age,
	c.givenname,
	c.surname
FROM
	sales s
LEFT JOIN -- will ensure that all the values of the common column from the left table i.e s be shown and their corresponding column values from table s and c(if the values is common b/w both tables) both be shown as
	customer c ON s.customerkey = c.customerkey
GROUP BY -- will group on the basis of mainly customer and then orderdate, i.e customerwise aggregation results for each date, rest are added cuz the aggregation requires the remaining columns to be GROUPED.
	s.customerkey,
	s.orderdate,
	c.countryfull, -- the customer table's columns called are added in GROUP BY even though its only one for each customer, because the other columns mentioned in SELECT have to be added in GROUP BY since we have mentioned aggregation function based entities in our SELECT clause.
	c.age,
	c.givenname,
	c.surname
)
SELECT 
	cr.customerkey,
	MIN(cr.orderdate) OVER(PARTITION BY cr.customerkey) AS first_purchase_date, ------------| -- We used OVER() & its PARTITION BY sub-clause here since we already have the grouped result i.e customer-wise & orderdate-wise result shown from the cr CTE, and since we used the aggregation functions here in the SELECT clause , we need to display the aggregation results for each individual row of the CTE's result set i.e already grouped hence it dosent make any significance if we GROUP BY them again on the basis of customerkey, hence we use PARTITION BY sub-clause within OVER() to get the row-wise aggregation result for each row in the result-set of the cr CTE.
	EXTRACT(YEAR FROM MIN(cr.orderdate) OVER(PARTITION BY cr.customerkey)) AS cohort_year --|
FROM 
	customer_revenue cr;