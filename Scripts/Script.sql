/* COALESCE & NULLIF Concepts :- */

-- 1) Create a sample table of jobs with their data :-
CREATE TABLE jobs_data (
	job_id INT,
	job_title VARCHAR(25),
	is_real VARCHAR(25),
	salary INT 
);

INSERT INTO jobs_data VALUES 
(1, 'Data Analyst', 'Yes', NULL),
(2, 'Data Scientist', NULL, 140000),
(3, 'Data Engineer', 'kinda', 120000);

SELECT * FROM jobs_data;

-- 2) Demonstration of COALESCE & NULLIF on recently created jobs_data table :-
SELECT 	
	job_id,
	job_title,
	COALESCE(is_real, 'no') AS is_real, -- this will callout the column of 'is_real' and for all the NULL values from is_real column will be replaced with 'no'.
	COALESCE(salary :: TEXT, job_title) AS salary -- This will callout the column of salary , and for all the NULL values inside will be replaced with that row's corresponding job_title column, but for that to happen we have to make sure we are extracting the salary column whose data type conversion has been done to TEXT type data, since replacing INT type NULL data with TEXT/VARCHAR can't be done, and has to be similar type of data.
FROM
	jobs_data;

-- 3) Finding the customers'(paying and non-paying seperately) total_net_revenue using COALESCE & NULLIF :-
WITH customer_rev AS (
SELECT 
	c.customerkey,
	SUM(s.netprice * s.quantity * s.exchangerate) AS total_net_revenue
FROM -- will ensure that all the customerkeys retrieved corresponding to the aggregation results of total_net_revenue are taken for all customers mentioned in customers table , and their corresponding info of sales(aggregated total) be shown from sales table if they exist in sales table , if no sale has been made by the customer then it will display NULL for its corresponding sales table info.
	customer c 
LEFT JOIN 
	sales s ON c.customerkey = s.customerkey 
GROUP BY 
	c.customerkey
)
SELECT 
	AVG(cr.total_net_revenue) AS avg_net_revenue_paying_customers, -- will show the avg value of net revenue spent by all paying customers who have made a sale in sales table (i.e NULL values will be ignored from the average).
	AVG(COALESCE(cr.total_net_revenue, 0)) AS avg_net_revenue_all_customers -- will coalesce and replace all the NULL values in total_net_revnue corresponding to each customers from the customer_rev CTE which inturn retrieves all the customers from customers table(i.e all customers in total paying & non-paying), and find their average after all the null values are replaced with 0 and hance will be changing the overall average significantly.
FROM 
	customer_rev cr;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/* String Functions */

-- UPPER, LOWER & TRIM Functions :-
SELECT 
	LOWER('HARSH MENON') AS lower_case, -- will give the lower case result for the mentioned text.
	UPPER('harsh menon') AS upper_case, -- will give the upper case result for the mentioned text.
	TRIM(BOTH '@' FROM '@@Harsh Menon@@') AS trimski -- Will trim both the leading aswel as the trailing mentioned character i.e '@' from the mentioned text.
	
-- CONCAT function (for which we will replace the earlier created view of cohort_analysis with the new view with same name i.e cohort_analysis[for which we will have to drop the earlier view], but here we concat the givennme & lastname) :-
DROP VIEW cohort_analysis;
	
CREATE OR REPLACE VIEW public.cohort_analysis AS 
WITH customer_revenue AS (
         SELECT s.customerkey,
            s.orderdate,
            sum(s.netprice * s.quantity::double precision * s.exchangerate) AS total_net_revenue,
            count(s.orderkey) AS order_count,
            c.countryfull,
            c.age,
            c.givenname,
            c.surname
           FROM sales s
             LEFT JOIN customer c ON s.customerkey = c.customerkey
          GROUP BY s.customerkey, s.orderdate, c.countryfull, c.age, c.givenname, c.surname
        )
 SELECT customerkey,
    orderdate,
    total_net_revenue,
    order_count,
    countryfull,
    age,
    CONCAT(TRIM(givenname), ' ', TRIM(surname)) AS clean_name, -- Will ensure that the given name and surname get concatenated/joined with a space in between them, also ensuring that there are no pre-existing unwanted spaces in the givenname or surname using TRIM function.
    min(orderdate) OVER (PARTITION BY customerkey) AS first_purchase_date,
    EXTRACT(year FROM min(orderdate) OVER (PARTITION BY customerkey)) AS cohort_year
   FROM customer_revenue cr;

SELECT * FROM cohort_analysis;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


/* Query Optimization :- */

-- EXPLAIN & EXPLAIN ANALYZE Intro :-
EXPLAIN -- Will show the scan type i.e seq scan/index scan, and then it shows also shows the info of no. of rows, width of each row and the cost(it represents the cost of resources it took to make the query's plan)
SELECT * FROM sales;

EXPLAIN ANALYZE -- Will show all the info shown in EXPLAIN(like cost, rows and row width) and will also show the planning time and execution time which will help us analyze if which form of writing down the query helps with analyzing the fastest query execution.
SELECT * FROM sales;

-- Basic Query Optimization Rules :-

	-- 1) For better query execution and runtime optimization , dont use 'SELECT *', rather use 'SELECT column/entity_name, ...', this will help in parsing lesser rows and hence executing this data will be easier and faster.
	EXPLAIN ANALYZE -------------|
	SELECT * FROM sales; --      | 
						 --		 |-- The difference stays on the favour of the first query even though it used SELECT * while the 2nd one didn't, thats because in both cases all the rows were parsed using Seq Scan and in one all the column values for all the rows were retrieved , while for the second one only one column's values for all rows were retrieved. But not using 'SELECT *' and using 'SELECT column/entity_name' will show a crucial difference if it was a Index scan proving retrieving all column's values will take longer execution times compared to an index already existing in a column value.
	EXPLAIN ANALYZE--------------|
	SELECT customerkey
	FROM sales;

	-- 2) For better and faster Query execution make use of LIMIT statements, it will limit the resourse usage and result in faster execution times :-
	EXPLAIN ANALYZE -------------|
	SELECT * FROM sales; --      |
						 --		 |-- As we can see here the query with no LIMIT statement used takes longer execution times than the one which uses.
	EXPLAIN ANALYZE--------------|
	SELECT * FROM sales
	LIMIT 10;
	
	-- 3) Make use of WHERE for filtering instead of HAVING in places possible for faster execution times, since the WHERE filter will filter in the initial part of the query execution (i.e in the parsing through the table stage) and will result in faster execution time, while the HAVING filter is executed in the later stage of the Query execution(i.e with the grouping and aggregation stage instead of being done with the parsing stage).
	-- query 1 :-
	EXPLAIN ANALYZE ---------------------------------------------------------|
	SELECT -- 																 |
		customerkey, --														 |
		SUM(netprice * quantity * exchangerate) AS revenue_of_customer --	 |
	FROM --																	 |
		sales --															 |
	WHERE -- 																 | -- As we can see the Query using WHERE filter in its execution takes us lesser execution time while the Query using HAVING filter takes up more execution time , the reason being un the 1st query using WHERE filter, the filtering takes place in the first part of the execution along with the parsing and hence only for those filtered rows, the grouping and aggregation will be done in its second stage of execution , whereas in Query 2 using the HAVING filter, the filtering takes place after grouping and aggregation is done , since HAVING clause is used to filter out aggregated values's conditions. and hence will be carried out in the seconf=d stage which takes up more resources and hence result in higher execution time.  
		orderdate >= '2024-01-01' --										 |
	GROUP BY -- 															 |
		customerkey; --														 |
	-- 																		 |
	-- query 2:- 															 |
	EXPLAIN ANALYZE ---------------------------------------------------------|
	SELECT 
		customerkey,
		SUM(netprice * quantity * exchangerate) AS revenue_of_customer
	FROM 
		sales
	GROUP BY
		customerkey
	HAVING SUM(netprice * quantity * exchangerate) > 1000;

-- Intermediate Query Optimization Rules :-

	-- 1) If possible try to avoid GROUP BY, but when necessary only add those columns for grouping which play crucial role in grouping and aggregation and are absolutely needed to solve the problem :-
	-- Query 1 :
	EXPLAIN ANALYZE
	SELECT
		customerkey,
		orderdate,
		orderkey,
		linenumber,
		SUM(netprice * quantity * exchangerate) AS revenue
	FROM
		sales
	GROUP BY
		customerkey,
		orderdate,
		orderkey,
		linenumber;

	/* Here as we can see we didnt need to retrieve the orderkey & linenumber out of the order, since its unique to each order, hence the SUM of net_revenue corresponding to that cohort group will result in the net revenue of the individual order, which we would have got without aggregating(i.e using SUM()).
	   Hence in the next Query we remove these two columns retrieved in the SELECT clause as well as GROUP BY clause, since if we mwntion those two columns in SELECT clause then we will have to also include them in GROUP BY clause cuz we are finding an aggregated value of SUM of net_revenue corresponding to those groups,
	   when we run the query after that as mentioned below we will notice that the execution time has been reduced significantly. */
	
	-- Query 2 :
	EXPLAIN ANALYZE
	SELECT
		customerkey,
		orderdate,
		SUM(netprice * quantity * exchangerate) AS revenue
	FROM
		sales
	GROUP BY
		customerkey,
		orderdate;

	/* As we can see over here we have removed the orderkey & linenumber info being retrieved in the query from GROUP BY clause aswell as SELECT clause, since if we would have mentioned in SELECT clause, then we would have to mention them in GROUP BY clause aswell since we are retreiving Aggregated values(i.e SUM of net_revenue) corresponding to them for all the columns and their groups mentioned in SELECT clause, 
	   and it has to be grouped since aggregated values cant be displayed alongside individual row values unless we use window functions, which we didnt use in this query... . The result as we are seeing has cost much less resource and hence resulted in a faster execution time as soon as we shortened the groupings within our earlier classified cohort groups, 
	   which now groups only on the basis of customerkeys and their orderdates and find their corresponding SUM of net_revenue by those customer on that orderdate which they have made an order in, unlike previously where we found the sum of net_revenue of the mentioned group of customer, for their mentioned orderdate, for which belongs to the same group of orderkey and linenumber which is unique to each order in sales, 
	   and hence will result in the net_revenue of each order itself in the aggregated SUM, for which we didnt need to use the GROUPING and Aggregation , hence we made the aggregation and grouping relevant for only those categories within mentioned columns in the GROUP BY clause, who needed the grouping and aggregation to show meaningful results unlike the previuos query. */
	
-- 2) Use as less JOIN statements as possible to optimize the query since the JOIN statements cause an extra stage to be added in the Seq/index Scanning which will be executed(before the seq/index scan is carried out on the table mentioned in FROM statement) and hence will cost up extra resources :-
	--Query 1 :
	EXPLAIN ANALYZE 
	SELECT 
		s.orderkey,
		s.customerkey,
		s.orderdate,
		c.givenname,
		c.surname,
		c.age,
		d.year
	FROM
		sales s
	JOIN customer c ON s.customerkey = c.customerkey -- will retrieve all the common values in the common column of sales and customer tables(i.e all the customers who have made a sale) , and find their corresponding info from the customer table and sales table as mentioned in select clause(i.e orderkey of all orders they have made, orderdate of their specefic order from sales table, their age, given name and surname from customer table).
	JOIN date d ON s.orderdate = d.date; -- Will retrieve all the common values of the common column 'orderdate'in sales and 'date' in date table, existing in both tables(which is basically all the orderdate of sales that are being explained in date table in the date column) and will find their corresponding info relating to that orderdate from date table i.e year corresponding that orderdate.
		
	/* As we see over here that the year retrieved corresponding to the orderdate has been retrieved from the date table afet inner joining the columns of s.orderdate and d.date from both tables to display only the dates/orderdates common in both tables(i.e orderdates), and find their corresponding year from date table. 
	   We can see over herewe clearly dont need the inner join with date column from date table to find the corresponding year to that orderdate, we can rather extract the year from the orderdate to find the year of that orderdate , which will remove the need of inner joining the sales table and date table. */
	
	-- Query 2 :
	EXPLAIN ANALYZE 
	SELECT 
		s.orderkey,
		s.customerkey,
		s.orderdate,
		c.givenname,
		c.surname,
		c.age,
		EXTRACT(YEAR FROM s.orderdate) AS year
	FROM
		sales s
	JOIN customer c ON s.customerkey = c.customerkey; -- will retrieve all the common values in the common column of sales and customer tables(i.e all the customers who have made a sale) , and find their corresponding info from the customer table and sales table as mentioned in select clause(i.e orderkey of all orders they have made, orderdate of their specefic order from sales table, their age, given name and surname from customer table).

	/* We can see the execution time of query 2 is faster than query 1 since we removed an extra join statement in query 2 which existed in query 1(the inner join of sales table and date table on the columns of s.orderdate & d.date) which would have added another step to the execution which would have costed some extra query planning resources and costed extra execution time... */
	
-- 3) Use as less columns in sorting and ordering in the ORDER BY clause as possible, because this also adds another process of adding an extra column/entity in the Sorting step which already takes place when we use ORDER BY clause. Hence use ORDER BY clause only when there is a genuine need of sorting for certain columns, and dont sub-sort columns which dont need sorting to be presentable :-
	-- Query 1 :
	EXPLAIN ANALYZE
	SELECT 
		customerkey,
		orderdate,
		orderkey, -- is unique to each order, but there can exists multiple line number for each of the products bought by the customer on that order(for how much ever quantity will be included within the same linenumber corresponding to the orderkey made by the customer).
		SUM(netprice * quantity * exchangerate) AS net_revenue -- will give the SUM of net_revenue of each of the product having different linenumbers bought within that orderkey, which belongs to a particular orderdate and that too for a customer.
	FROM
		sales
	GROUP BY -- will show the aggregated result(i.e SUM of net_revenue) corresponding to each cohort groups which consists of an orderkey, orderdate & customer, basically will find the total revenue of an order(for all its linenumbers) by the customer on their specefic orderdate.
		customerkey,
		orderdate,
		orderkey
	ORDER BY -- will sort the data firstly in descending order of their net_revenue, then for cohort_groups having the same net_revenue, the sorting will be done on the basis of customerkey secondly, orderdate thirdly, and orderkey fourthly.
		net_revenue DESC,
		customerkey,
		orderdate,
		orderkey
		
	/* We noticed over here that we didnt need to order/sort our resulting data in such a complex way , an easier way either only depending on net_revenue or customerkey could have been done individually for better representation of data.
	   So here we will try to sort them on the basis of customerkeys, orderdates and orderkeys in ascending order in the new query. */
	
	-- Query 2 :
	EXPLAIN ANALYZE
	SELECT 
		customerkey,
		orderdate,
		orderkey, -- is unique to each order, but there can exists multiple line number for each of the products bought by the customer on that order(for how much ever quantity will be included within the same linenumber corresponding to the orderkey made by the customer).
		SUM(netprice * quantity * exchangerate) AS net_revenue -- will give the SUM of net_revenue of each of the product having different linenumbers bought within that orderkey, which belongs to a particular orderdate and that too for a customer.
	FROM
		sales
	GROUP BY -- will show the aggregated result(i.e SUM of net_revenue) corresponding to each cohort groups which consists of an orderkey, orderdate & customer, basically will find the total revenue of an order(for all its linenumbers) by the customer on their specefic orderdate.
		customerkey,
		orderdate,
		orderkey
	ORDER BY -- will sort the data firstly in ascencding order of their customerkeys , for the cohort groups having same customerkeys, they will be arranged on the basis of their orderdate in ascending order secondly, similarly thirdly on the basis of orderkey.
		customerkey,
		orderdate,
		orderkey 
	/* As we can see the execution time for this second query having less columns on the basis of which we are sorting it by, will have lesser columns to be added in the sorting stage of the query execution and hence will cost up less resources resulting in faster execution time than query 1 which has more columns/entities on the basis of which we have to sort in the sorting stage of query execution, which cost up more resources and hence took more execution time. */
	

-- Query Optimization real-world examples(by optimizing the previously created cohort_analysis view and replacing that old version of the view with new optimized version) : 

/* Here the optimizations done include :-
   - The Left join done in customer_revenue CTE will be replaced with INNER JOIN/JOIN since it will only display those values which are common in both tables, hence will use up less resources resulting in quicker execution time when doing the index scan instead of seq scanning.
   - We can see that we have used too many columns inside of the GROUP BY clause which we dont actually need , sice its further info related to customerkey, which will remain the same for each customerkey, hence is repeating conidering we have already called customerkey in GROUP BY,
     so our new cohort group will only include customerkey and orderdate to display the total revenue & order count by the customer on that particular orderdate, and the rest of the info will be added in their own aggregarion function like MAX() which will same result, since the given info is the same for each customerkey and the max of those values will be  */
	
	DROP VIEW cohort_analysis;	
		
	CREATE OR REPLACE VIEW cohort_analysis AS
	WITH customer_revenue AS (
	SELECT
		s.customerkey,
		s.orderdate,
		sum(s.netprice * s.quantity::double precision * s.exchangerate) AS total_net_revenue,
		count(s.orderkey) AS order_count,
		MAX(c.countryfull) AS countryfull, -------|
		MAX(c.age) AS age, -----------------------|
		MAX(c.givenname) AS givenname, -----------| -- The MAX of these column values from customer table corresponding to that customerkey from sales table will give basically the same info/data mentioned in those columns, since the query takes it as a group which are multiple for a given customerkey, but as we know its one and singular for each customerkey in customer table and hence will also be the same way for customerkey displayed which is from sales table(customers who have made a sale, i.e from sales table, since customer table already has all the customers mentioned in the sales table and also has customers who havent made any sale), hence the MAX of them will also result in the same data which is displayed when not using an aggregation on them.
		MAX(c.surname) AS surname ----------------|
	FROM
		sales s
	INNER JOIN customer c ON
		s.customerkey = c.customerkey
	GROUP BY
		s.customerkey,
		s.orderdate
)
 SELECT
	customerkey,
	orderdate,
	total_net_revenue,
	order_count,
	countryfull,
	age,
	concat(TRIM(BOTH FROM givenname), ' ', TRIM(BOTH FROM surname)) AS clean_name,
	min(orderdate) OVER (
		PARTITION BY customerkey
	) AS first_purchase_date,
	EXTRACT(year FROM min(orderdate) OVER (PARTITION BY customerkey)) AS cohort_year
FROM
	customer_revenue cr;
	
	