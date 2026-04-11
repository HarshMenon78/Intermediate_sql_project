# 📊 Salses Analysis Project - Contoso_100k Dataset

---

## 📌 Overview
This project focuses on performing **end-to-end data analysis using SQL** on the `contoso_100k` database.

The primary goal is to solve **real-world business problems** using structured SQL techniques and derive **actionable insights** from customer and sales data.

This project demonstrates:

- Customer segmentation using **LTV (Lifetime Value)**
- **Cohort-based revenue analysis**
- **Customer churn & retention analysis**
- Use of **CTEs, window functions, aggregations, and cohort logic**

---

## 🗄️ Database & Setup

### 📦 About the Dataset
The `contoso_100k` database is a **retail-style dataset** that simulates:

- Customer purchase behavior  
- Sales transactions over time  
- Revenue generation patterns  

It is highly suitable for:
- Cohort analysis  
- Customer segmentation  
- Revenue analytics  

---

### ⚙️ Database Creation & Loading

#### Step 1: Create Database
An empty database was first created in PostgreSQL using **pgAdmin4** inside the Query Editor :

```sql
CREATE DATABASE contoso_100k;
```
### ⚙️ Step 2: Load Dataset

The dataset was loaded using a `.sql` file containing:

- Table creation scripts  
- Schema definitions  
- Data insert statements  
- Constraints and configurations  

📥 **Dataset Source:**  https://github.com/lukebarousse/Int_SQL_Data_Analytics_Course/releases/tag/v.0.0.0

Once executed, this file automatically:

- Created all required tables  
- Inserted data into them  
- Set up relationships and structure  

---

## 🧾 Key Tables

### 🛒 `sales`

- Contains transaction-level data  

**Includes:**
- `orderdate`
- `customerkey`
- `netprice`, `quantity`, `exchangerate`

**Used for:**
- Revenue calculations  
- Purchase behavior analysis  

---

### 👤 `customer`

- Contains customer-level information  

**Includes:**
- Demographics  
- Names, age, location  

**Used for:**
- Customer segmentation  
- Enrichment of sales data  

---

### 📊 `cohort_analysis` (Derived View)

- Created as a base analytical layer  

**Combines:**
- Customer data  
- Revenue data  
- Cohort information  

**Includes:**
- `first_purchase_date`
- `cohort_year`
- `total_net_revenue`

---

## ❓Business Questions

### 🔹 Problem 1: Customer Segmentation (LTV)
How can we segment customers based on their lifetime value, and which segment contributes the most revenue?

---

### 🔹 Problem 2: Revenue Timing Analysis
When do customers generate the most revenue after their first purchase?

---

### 🔹 Problem 3: Customer Churn Analysis
Which customers are active vs churned, and how does their revenue contribution differ?

---

## 🧠 Analysis Approach

### 🔹LTV-Based Customer Segmentation

- Calculated customer lifetime value (LTV)  
- Used percentiles (25th & 75th) to segment customers  

**Segments:**
- Low Value  
- Medium Value  
- High Value  

**Analysis Performed:**
- Revenue contribution by segment  
- Percentage share of total revenue  

📊 **Visualization 1:**  
![Customer Segmentation](images/1_customer_segmentation.png)

---

### 🔹Cohort Revenue Timing Analysis

**Calculated:**
```sql
orderdate - first_purchase_date AS days_since_first_purchase
```
- Grouped revenue by time difference  
- Identified when revenue is concentrated  

🔍 **Key Finding:**
- Majority of revenue (~61%) occurs on the first purchase day  

**Further Analysis:**
- Cohort_year-wise revenue  
- Customer count  
- Average revenue per customer
- For the `first_purchase_date`

📊 **Visualization 2:**  
![Customer Group Revenue Analysis](images/2_customer_group_revenue_analysis.png)

---

### 🔹Customer Churn & Retention Analysis

**Defined churn using:**
```sql
last_purchase_date[of customer] vs MAX(orderdate)[last_purchase_date_overall]
```
**Customer Classification:**
- **Active** → Purchased within last 6 months of last purchase date of the entire sales data.
- **Churned** → No recent purchases  

**Analysis Performed:**
- Revenue contribution by status  
- Cohort-wise churn distribution  
- Customer count percentages  

📊 **Visualization 3:**  
![Customer Churn Analysis - Overall Sales Data](images/3_customer_churn_analysis(for%20overall%20sales%20data).png)

![Customer Churn Analysis - Cohort Year & Status Distribution](images/3_customer_churn_analysis(cohort_year%20%26%20status%20wise%20distribution).png)

---

## 📈 Business Insights

### 💡 Key Findings

**Revenue Concentration**
- A large portion of revenue comes from first-time purchases  

**Customer Value Distribution**
- High-value customers contribute a disproportionate share of revenue  

**Churn Behavior**
- Significant number of customers become inactive after initial purchase  

**Cohort Trends**
- Different cohorts show varying retention and revenue patterns  

---

## 🚀 Strategic Recommendations

### 🎯 Improve Customer Retention
- Focus on post-first purchase engagement  

**Introduce:**
- Loyalty programs  
- Follow-up campaigns  

---

### 📉 Improve Low-Value Customer Contribution
- Enhance purchasing experience for low-value customers to increase their engagement and spending  

**Focus Areas:**
- Simplify checkout and reduce friction  
- Provide targeted discounts or bundles for low-spend users  
- Use personalized recommendations to encourage repeat purchases  
- Introduce entry-level loyalty incentives to gradually increase LTV  

---

### 💰 Maximize High-Value Customers
- Identify and target high LTV customers  

**Offer:**
- Exclusive deals  
- Personalized experiences  

---

### 🔁 Reduce Churn
- Re-engage churned users through:

- Email campaigns  
- Discounts  
- Product recommendations  

---

### 📊 Optimize First Purchase Experience
- Since most revenue comes early:

- Improve onboarding  
- Optimize first purchase journey  

---

## ⚙️ Technical Details

### 🧩 SQL Concepts Used

- **PostgreSQL & pgadmin4** - [To create, access & manipulate data in our database using SQL Querying] 
- **DBeaver** - [for viewing the contents of a Views & Tables contents we created allowing remote & quick access of the Source code of views we created]
- **VS-Code** - [For Project folder setup and repository creation & Uploading]
- **Claude.ai** - [Vizualizations]

---

### 🏗️ Key Pattern Used

```sql
SUM(x) / SUM(SUM(x)) OVER(PARTITION BY y)
```
- Allowing the inside `SUM(total_net_revenue)` be aggregated for `total_net_revenues` of `cohort_analysis` view's cohorts, using the entities mentioned in the `GROUP BY` clause i.e the new cohort groups of `cohort_year` & `customer_status` for all the older cohorts whose `customerkeys` fall under the category of mentioned new cohort groups(`cohort_year` & `customer_status`).

- The outter `SUM(SUM(..)) OVER(PARTITION BY cohort_year)` ensures that the result of `SUM(total_net_revenue)` i.e `cohort_year` & `customer_status` wise `total_net_revenue` of previous cohorts whose customers have the mentioned above new cohort's values, get aggregated to the outter `SUM()` which is a window function for each partitioned `cohort_year` i.e will result the SUM of all the `total_net_revenues` belonging to that `cohort_year` irrespective of their `customer_status` (since the aggregation on the basis of the mentioned entities in thr `GROUP BY` clause has already be done in the inner `SUM()`).

- This helps us find the percentage values of what the revenue and customer count of the `customer_status` of that `cohort_year` makes up to the total revenue and total customer count of the `cohort_year`.


