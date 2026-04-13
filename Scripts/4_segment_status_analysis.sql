/* 
Problem 4 : Analyze the status-related data of each customer segment and understand their performance metrics :- 
- We will get to understand the customer distribution across different segments with their respective performance indicators to know which segment customers have the highest performance.
- For this we will copy paste the previous query's CTEs(1_customer_segmentation) from the previous problem 1 and modify its main query to include the status-related data.
- Also we will have to pull the status-related data from the CTEs of the previous query(3_customer_status) , and then in the main query of our current query find out the segment & status-wise distribution of customers helping us get to know their performance(the more active customers in each segment, the better their performance is).
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
), customer_date_info AS (-- In this CTE we will find out last_purchase_date of each of the customer mentioned in cohort_analysis view.
    SELECT
        customerkey,
        orderdate,
        total_net_revenue, -- for the customers on their corresponding orderdates.
        cohort_year,
        first_purchase_date,
        MAX(orderdate) OVER(PARTITION BY customerkey) AS last_purchase_date -- To find the last purchase date of customers from the cohort distribution(customerkey & their orderdates) of cohort_analysis view based on how they compare to the last purchase date of the entire sales data, we can assign them their status as active/inactive accordingly in the next CTE.
    FROM
        cohort_analysis
), customer_status AS ( -- we created this 2nd CTE to find out the customer_status of each of those cuustomers from customer_analysis view whose last_purchase_date we recently found out, and on the basis of their last_purchase_date of each customer compared to the last_purchase_date overall of the entire sales data, we are going to assign customer statuses of Active and Churned to each customer.
    SELECT
        cd.*,
        CASE -- Makes sure that if a customer's last purchase date lies between the period of last purchase date of the entire sales data and the date 6 months before the last purchase date of the entire sales data, the customer is marked as 'Active'; otherwise they are 'Churned'.
            WHEN (cd.last_purchase_date > ((SELECT MAX(orderdate) FROM sales) - INTERVAL '6 Months'))
                  AND (cd.first_purchase_date < ((SELECT MAX(orderdate) FROM sales) - INTERVAL '6 Months')) THEN 'Active'
            ELSE 'Churned'
        END AS status
    FROM
        customer_date_info cd
)
SELECT
    customer_segment.ltv_segment,
    customer_status.status,
    COUNT(DISTINCT customer_segment.customerkey) AS customer_count_of_the_segment_for_status, -- Will find the count of customers for the mentioned ltv segment which lie within their respective status groups. ---------------------------------------------------------------------------------------------------------------------------------------------|
    SUM(customer_status.total_net_revenue) AS revenue_of_segment_by_status, -- Will find the SUM of the total_net_revenue(of cohort groups of cohort_analysis i.e customerkey & their orderdate) for all those customers who fall within the same ltv_segment and also have the same status(i.e new cohort of main query of ltv_segment & their statuses). ----|-- Even though we have mentioned customer_segment.customerkey for COUNT & customer_status.total_net_revenue for SUM here, it will give us the COUNT of customers and the SUM of their total_net_revenue for all the customerkeys from the data(combining both customer_segment & customer_status CTEs) who fall within the same category of sharing the same cohort charecterstics i.e falling under the same ltv_segment & also having the same status, for all those customers their count and the sum of their total_net_revenue from cohort_analysis view will be counted.
    (COUNT(DISTINCT customer_segment.customerkey) / SUM(COUNT(DISTINCT customer_segment.customerkey)) OVER(PARTITION BY customer_segment.ltv_segment)) * 100 AS percentage_of_customers_in_status_and_segment_with_the_segment_combined_customers -- Will find the percentage of customers in each status and segment combination with respect to the total customers in that segment(combining all statuses of that segment) to get a better understanding of the distribution of customers across different segments and their respective performance indicators. This will help us understand which segment customers have the highest performance based on their distribution across different statuses.
FROM -- Since we are finding out the ltv_segment from the CTE of customer_segment, on the basis of which we are doing the first phase of grouping our new cohort(of ltv_segment & status), This will include the customerkeys falling under that ltv_segment based on their ltvs.
    customer_segment
JOIN -- Since we want the corresponding status of the customer too along side the ltv_segments to which each of these customers belong to(which we got in customer_segment), here the info will be retrieved for the combined info of all customers in a customer-info type distribution which is not displayed directly, but since our query has the knowledge of which customerkeys belong to which ltv_segment and status through the CTEs created , the customers with corresponding same ltv_segment & status as mentioned in new cohort... their info of total_net_revenue's(from cohort_analysis's old cohort of customerkey and their orderdate) SUM of all such similar customers and the count of all these similar customers based on their new cohorts will be displayed corresponding to their new cohorts.
    customer_status ON customer_segment.customerkey = customer_status.customerkey
GROUP BY -- Creating new cohorts of ltv_segments and status, so that we can find the aggregated results of customer_count_of_the_segment_for_status and revenue_of_segment_by_status foor all the customers falling under the category of that ltv_segment and status(new cohorts).
    customer_segment.ltv_segment,
    customer_status.status;

/* 
In the second part of the entity 'percentage_of_customers_in_status_&_segment_with_the_segment_combinded_customers' i.e the part after '/', we have mentioned the COUNT(DISTINCT customer_segment.customerkey) in the inner query, which will find the count of customers falling within that cohort of sharing the same segment and status, since it will be aggregated on the basis of the entities mentioned in the GROUP BY clause, and hence is supposed to hold the distibution of each segment and the status , showing the count of customers within that segment for each status in a distributed pattern...
When we mentioned the Outter query/aggregation of SUM(...) OVER(PARTITION BY customer_segment.ltv_segment) we are calling a window function aggregation over the previous inner aggregation mentioned inside of the 'SUM()', hence will give the SUM of the Count of all the customers for both status inside the segments of the cohorts, basically the total customer count of that entire segment cobining both the statuses and their indivual customer_counts, and hence overall in that entity will result us with the customer count witin each segment divided by the customer count of the entire segment, giving us the percentage of customers in each status and their segment compared the total customers in that segment. 
*/