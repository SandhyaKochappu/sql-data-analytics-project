# SQL Data Analytics Project

This project showcases key SQL techniques and analytical methods for deriving business insights from sales and customer data. The goal is to support strategic decision-making, performance tracking, and customer segmentation through a series of analytical tasks.

---

## 📈 1. Change Over Time Analysis

**Objective:**  
Analyze sales performance over time to track trends and identify seasonality.

**Key Concepts:**
- Measure metrics by date dimension.
- Calculate total sales by year.
- Calculate average cost by month.

**Tasks:**
- Analyze sales performance change month-over-month.
- Discover seasonal trends in the dataset.

---

## 📊 2. Cumulative Analysis Using Window Functions

**Objective:**  
Understand the growth of the business over time using progressive aggregation.

**Key Concepts:**
- Use window functions for cumulative measures.
- Calculate running total of sales by year.
- Compute moving average of sales by month.

**Tasks:**
- Calculate total sales per month and the running total of sales over time.

---

## 🚀 3. Performance Analysis

**Objective:**  
Compare actual performance to target or previous performance to measure success.

**Key Concepts:**
- Compare each product’s current sales to:
  - Its average performance.
  - Its previous year’s sales.

**Tasks:**
- Analyze yearly performance of products.

---

## 🏆 4. Top Categories by Sales

**Objective:**  
Identify the categories that contribute the most to overall sales.

**Task:**
- Determine which categories are the top contributors to total sales.

---

## 🎯 5. Data Segmentation

**Objective:**  
Segment products into cost ranges to understand product distribution.

**Task:**
- Group products by cost range.
- Count how many products fall into each segment.

---

## 👥 6. Build Customer Report

**Objective:**  
Classify customers based on their spending behavior and analyze customer-level metrics.

**Segmentation Rules:**
- **VIP**: Customers with ≥12 months of history and spending > $5,000.
- **Regular**: Customers with ≥12 months of history but spending ≤ $5,000.
- **New**: Customers with <12 months of history.

**Tasks:**
- Calculate the number of customers in each segment.
- Aggregate customer metrics:
  - Total orders
  - Total sales
  - Total quantity purchased
  - Total distinct products
- Calculate KPIs:
  - Recency (months since last order)
  - Average order value (AOV)
  - Average monthly spend

---

## 📦 7. Build Product Report

**Objective:**  
Summarize product-level performance metrics and categorize products by revenue contribution.

**Tasks:**
- Segment products into:
  - High performers
  - Mid-range performers
  - Low performers
- Aggregate product metrics:
  - Total orders
  - Total sales
  - Total quantity sold
  - Total unique customers
  - Customer lifespan in months
- Calculate KPIs:
  - Recency (months since last sale)
  - Average Order Revenue (AOR)
  - Average Monthly Revenue (AMR)

---

## 🛠️ Tools & Techniques

- SQL (Window functions, Aggregate functions, Case statements)
- Power BI
- Date/time functions
- Analytical thinking
- Customer and product segmentation

---

## 📌 Notes

This project is intended to demonstrate practical SQL applications for business intelligence, with a focus on building dashboards and reports that help stakeholders understand performance, customer behavior, and key trends in the business.

