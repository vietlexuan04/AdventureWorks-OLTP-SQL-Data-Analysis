# AdventureWorks OLTP — SQL Data Analysis
A comprehensive business analysis of Adventure Works using pure T-SQL on the OLTP 2022 dataset.
This project goes beyond querying data. It dives deep into root cause analysis, financial performance evaluation, and customer segmentation via an RFM model built entirely in SQL.
## 🎯 Objectives
- Analyze revenue trends over time
- Identify top customers and their contribution
- Detect high-risk products (low profit/losses)
- Segment customers using RFM model
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
##🗃️ Dataset
| **Source**       | AdventureWorks 2022 — Microsoft Sample Databases |
|------------------|--------------------------------------------------|
| **Type**         | OLTP (Online Transaction Processing)             |
| **Period**       | 2011 – 2014                                      |
| **Key Schemas**  | Sales, Production, Purchasing, Person            |




