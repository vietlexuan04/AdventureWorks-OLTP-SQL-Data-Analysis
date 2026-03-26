# AdventureWorks OLTP — SQL Data Analysis
This project analyzes the AdventureWorks OLTP dataset to uncover revenue drivers, identify profit leakage, and segment customers for strategic decision-making.
**Key highlights:**
- Identified that 10% of customers drive 68% of revenue
- Discovered 21% of products are loss-making
- Revealed B2B channel generates ~75% of total revenue with 20× higher AOV

See full insights here: [insights.md](insights.md)
## 🏢 Business Context
This project simulates a real-world business scenario in which a data analyst supports decision-making across sales, product, and customer strategy within a retail/manufacturing company.
## 🎯 Objectives
- Analyze revenue trends over time
- Identify top customers and their contribution
- Detect high-risk products (low profit/losses)
- Segment customers using the RFM model
## 🛠️ Tools & Skills
- SQL Server Management Studio
- Data Analysis
- Business Thinking
## 📁 Project Structure
```
AdventureWorks-OLTP-Analysis/
│
├── SQL/
│   ├── 00_data_exploration.sql      ← Data validation & channel classification
│   ├── 01_adhoc_analysis.sql        ← Ad-hoc business questions
│   ├── 02_kpi_metrics.sql           ← KPI & financial metrics
│   └── 03_rfm_model.sql             ← Customer segmentation (RFM model)
│
├── images/
│   └── adventureworks_schema.png    ← Database schema diagram
│
├── docs/
│   └── README_VI.md                 ← Vietnamese version of this README
│
└── README.md
```
## 🗃️ Dataset
| **Source**       | [AdventureWorks 2022 OLTP — Microsoft Sample Databases](https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver17&tabs=ssms) |
|------------------|-------------------------------------------------------|
| **Type**         | OLTP (Online Transaction Processing)                  |
| **Period**       | 2011 – 2014                                           |
| **Key Schemas**  | Sales, Production, Purchasing, Person                 |

![Schema](./images/adventureworks_schema.png)

## 📊 Analysis Overview
**Part 1: Ad-hoc Analysis**
Answering key business questions across Sales, Product, and Purchasing domains:
- Quarterly revenue trends and seasonality patterns
- Revenue ranking by sales territory
- Online vs. Offline channel breakdown: order volume & revenue share (B2C vs B2B)
- Top 5 customers by revenue contribution, segmented by customer type
- Top 10 most profitable products
- Vendor rejection rate analysis (overall + drilled down by product SKU)

**Part 2: KPI & Financial Metrics**
- Gross profit margin by quarter
- Average Order Value (AOV) by sales channel
- Loss-making product rate (21% of all products carry negative margins)
- Quarterly profit margin comparison: high-profit lines (Mountain-200, Road-150) vs. low-profit lines (Touring-1000, Road-650)
- Top scrap reasons in manufacturing

**Part 3: RFM Customer Segmentation Model**
Built entirely in T-SQL, no external tools. Segments all customers into 8 behavioral groups based on:
- Recency: Days since last purchase
- Frequency: Number of distinct orders
- Monetary: Total revenue generated
Uses PERCENT_RANK() window functions to score each dimension 1–4, then maps combined RFM codes to actionable customer segments.

## 🛠️ SQL Techniques Used
- Multi-level CTEs for modular, readable analytical pipelines
- Window Functions: LAG(), RANK(), DENSE_RANK(), PERCENT_RANK(), SUM() OVER(PARTITION BY ...)
- Conditional aggregation with CASE WHEN inside aggregate functions
- Temp Tables (#table) to persist intermediate results across RFM scoring stages
- Multi-schema JOINs across Sales, Production, and Purchasing

## 💡 Key Findings
- Offline channel (B2B) generates ~75% of total revenue, despite far fewer orders. Offline AOV is approximately 20× higher than Online.
- 60% of total profit comes from just 2 product lines: Mountain-200 and Road-150.
- 21% of products (56/266) carry negative profit margins, while the top-performing lines are effectively subsidizing these losses.
- RFM insight: Potential Loyal and Best Customer segments represent only ~10% of customers but contribute 68% of total revenue. The Lost Big Customer group (low Recency, high Monetary) accounts for 16% of historical revenue, a significant win-back opportunity.

## 📌 Business Recommendations
- Focus on retaining the top 10% customers who drive the majority of revenue
- Review and optimize or discontinue loss-making products
- Expand B2B (offline) channel due to significantly higher AOV
- Implement targeted win-back campaigns for high-value inactive customers  

## 👤 Author
Le Xuan Viet
