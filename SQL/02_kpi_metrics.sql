-- PART 2: COMPANY-LEVEL KPI METRICS
-- KPI 1: Gross profit margin by quarter
WITH Finance AS (    
    SELECT
        DATEPART(YEAR, soh.OrderDate) AS OrderYear,
        DATEPART(QUARTER, soh.OrderDate) AS OrderQuarter,
        SUM(sod.LineTotal) AS TotalRevenue,
        SUM(sod.OrderQty * p.StandardCost) AS TotalCost,
        SUM(sod.LineTotal) - SUM(sod.OrderQty * p.StandardCost) AS Profit
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.SalesOrderDetail sod
        ON soh.SalesOrderID = sod.SalesOrderID
    JOIN Production.Product p
        ON sod.ProductID = p.ProductID
    GROUP BY DATEPART(YEAR, soh.OrderDate),
        DATEPART(QUARTER, soh.OrderDate)
)

SELECT
    *,
    CAST(Profit*100.0 / TotalRevenue AS DECIMAL(8,2)) AS ProfitRate
FROM Finance
ORDER BY OrderYear, OrderQuarter

/*
  Insight:
  - Profit margin declined steadily and bottomed out in Q2/2012 (-3.11%), remaining very low
    (below 4%) all the way through Q2/2013 — despite revenue generally growing during this period.
  - The company entered a "growth without efficiency" phase, partially driven by heavy resource
    allocation toward low-margin products (Touring-1000, Road-650) during the same window.
  - From Q3/2013 to 2014, margin recovered and peaked in Q2/2014, coinciding with
    Touring-1000 and Road-650 margins turning positive and trending upward.
*/


-- KPI 2: Average Order Value (AOV) by sales channel
SELECT
CASE 
WHEN soh.OnlineOrderFlag = 1 THEN 'Online'
ELSE 'Offline'
END AS SalesChannel,

COUNT(DISTINCT soh.SalesOrderID) AS TotalOrders,
SUM(soh.SubTotal) AS TotalRevenue,
CAST(SUM(soh.SubTotal) * 1.0 / COUNT(DISTINCT soh.SalesOrderID) AS DECIMAL(10,2)) AS AOV

FROM Sales.SalesOrderHeader soh
GROUP BY soh.OnlineOrderFlag
ORDER BY SalesChannel

/*
  Insight:
  - Company revenue is heavily dependent on the Offline channel: Offline AOV is approximately 20× higher than Online AOV.
  - However, the Online channel provides much broader reach to individual customers.
  - These two channels require fundamentally different marketing strategies:
      · Offline: focus on account management and nurturing high-value B2B relationships.
      · Online: focus on increasing basket size through bundle/combo product offerings.
*/



-- KPI 3: Loss-making product rate = products with negative profit / total products
WITH ProductProfit AS (
    SELECT
        p.ProductID,
        p.Name,
        SUM(sod.LineTotal) AS TotalRevenue,
        SUM(sod.OrderQty * p.StandardCost) AS TotalCost,
        SUM(sod.LineTotal) - SUM(sod.OrderQty * p.StandardCost) AS TotalProfit
    FROM Sales.SalesOrderDetail sod
    JOIN Production.Product p
        ON sod.ProductID = p.ProductID
    GROUP BY 
        p.ProductID,
        p.Name
)

SELECT
    COUNT(CASE WHEN TotalProfit < 0 THEN 1 END) AS LossProducts,
    COUNT(*) AS TotalProducts,
    CAST(
        COUNT(CASE WHEN TotalProfit < 0 THEN 1 END) * 100.0 
        / COUNT(*) 
        AS DECIMAL(8,2)
    ) AS LossProductRate
FROM ProductProfit

/*
  Insight:
  - 56 out of 266 products (21.05%) carry negative profit margins — a significant figure,
    especially given that just 10 products (Mountain-200, Road-150) account for ~60% of total profit.
  - The company is effectively using profits from its top-performing lines to subsidize the bottom 20%.
  - The high loss-product rate may be a direct consequence of scrap costs being absorbed into COGS.
  - Beyond revenue-side growth campaigns (Online & Offline), the company should also audit
    these loss-making products for: appropriate pricing strategy, production quality control,
    and vendor optimization.
*/