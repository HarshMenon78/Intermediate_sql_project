/*
Problem 1 : Find out the customer_segments on the basis of their total_ltvs, and find out which group of customer_segments make the most revenue :-
- For this we will firstly create a CTE named customer_ltv, wherein we will find the ltv(i.e life time value) of each customer from the cohort_analysis view, by finding the SUM of total_net_revenue of all the cohort groups(of customerkeys and their orderdates) belonging to the customer's whose ltv we finding.
- Then we will create a second CTE called percentile_value, where we will find the 25%th & 75%th value respectively when the individual rows of previously created customer_ltv is arranged in ascending order of their total_ltv, in the next cte we will assign the customers customersegments based on these percentile_values found.
- We will create a 3rd CTE called customer_segment where we assign customer_segments to each of the customers and their info retreived from customer_ltv CTE on the basis of the percentile_values found in the 2nd CTE of percentile values(in the FROM statement we will call iN customer_ltv, and also percentile_values CTE) :
	- '1_Low_Value' - For all the customers having their total_ltv below the percentile_value_25%th(i.e less than the value of total_ltv which is in the 25%th position when all rows from customer_ltv CTE are arranged in ascending order of their total_ltvs).
	- '2_Medium_Value' - For all the customers having their total_ltvs falling between the 25%th and the 75%th percentile_value(when the rows/customer-info from customer_ltv CTE are arranged in ascending order of their total_ltv).
	- '3-High-Value' -  For all the customers having their total_ltv above the percentile_value_75%th(i.e more than the value of total_ltv which is in the 75%th position when all rows from customer_ltv CTE are arranged in ascending order of their total_ltvs).
- In the Main Query we will display the category-wise distribution of customer_segments by GROUPING them from the customer_segment CTE, and finding out their corresponding SUM of total_net_revenue of all cohort_groups(i.e customerkeys & their orderdates) having their customerkeys falling under the category as mentioned in theer corresponding group of customer_segment in the result-set, 
and also find how the SUM of total_net_revenues of all these customer_segments compared to the SUM of total_revenue of all the sales/customers/cohort-groups(from cohort_analysis view) all together combined.
*/

WITH customer_ltv AS ( -- In this CTE we will find the customer's total life time value.
SELECT 
	customerkey,
	clean_name,
	SUM(total_net_revenue) AS total_ltv
FROM
	cohort_analysis
GROUP BY -- Will ensure that the SUM of total_net_revenue for each cohort groups of customerkeys and their orderdates are grouped together in one for all their customers, hence to show the total_ltv of the customer.
	customerkey,
	clean_name
), percentile_value AS ( -- This CTE will find the 25%th and 75%th value of total_ltv column corresponding to each customer , when they are arranged in ascending order. This is done so that in the upcomming CTE we can arrange the customers based on their order-value segments into low/medium/high value.
SELECT
	PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY cl.total_ltv) AS percentile_value_25th,
	PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY cl.total_ltv) AS percentile_value_75th
FROM 
	customer_ltv cl
), customer_segment AS ( -- In this CTE we will make the segments for each of the total_ltv for the customers from customer_ltv CTE based on their value compared to the percentile values of the total_ltv when arranged in ascending order from the percentile_values CTE.
SELECT
	cl.*,
	CASE 
		WHEN cl.total_ltv < percentile_value_25th THEN '1-Low-Value'
		WHEN cl.total_ltv < percentile_value_75th THEN '2-Medium-Value'
		ELSE '3-High-Value'
	END AS ltv_segment
FROM
	customer_ltv cl, -- Since thats where we are importing our main entities of our segmentation i.e customer info and their corresponding total_ltv.
	percentile_value -- We are not joining them and rather just cross joining them because , we only need the percentile values from the percentile_value CTE and it holds no row-wise corresponding value info since there is no common column on the basis of which we can do that anyways.
)
SELECT -- In the main query we will group all the categories inside the ltv_segment entity from the customer_segment CTE and find their corresponding SUM of all the total_ltv of all the customers who lie within that ltv_segment, and also the percentage their SUM of total_ltv of that ltv_segment makes up to the SUM of all the net_revenues of each cohort group from cohort_analysis view i.e the combined total revenue of all customers in dataset.
	cs.ltv_segment,
	SUM(cs.total_ltv) AS total_segment_revenue, -- Will find out the sum of all the total_ltvs of all the customers falling within that particular group of ltv_segment.
	(SUM(cs.total_ltv) / (SELECT SUM(total_net_revenue) FROM cohort_analysis)) * 100 AS percentage_with_total_revenue -- Will find the percentage this ltv_segment's total_segment_revenue makes up to the whole of SUM of total_net_revenue of all the cohort groups in cohort_analysis CTE (i.e of all the customer's and their distinnct ordate's total_net_revenue's combined SUM).
FROM 
	customer_segment cs
GROUP BY -- Will ensure to GROUP all the categories inside of the entity of ltv_segment , and corresponding to them show the aggregated value mentioned i.e SUM of all the total_ltvs of all the customers falling under tat particular ltv_segment.
	cs.ltv_segment
ORDER BY 
	cs.ltv_segment;