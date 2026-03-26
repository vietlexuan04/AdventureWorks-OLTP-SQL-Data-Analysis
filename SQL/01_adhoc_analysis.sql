-- PART 1: AD-HOC BUSINESS QUESTIONS
-- Q1: Quarterly revenue trend (Sales)
WITH RevenueTable AS (
    SELECT
        DATEPART(YEAR, soh.OrderDate) AS OrderYear,
        DATEPART(QUARTER, soh.OrderDate) AS OrderQuarter,
        SUM(soh.SubTotal) AS TotalQuarterlyRevenue
    FROM Sales.SalesOrderHeader soh
    GROUP BY 
        DATEPART(YEAR, soh.OrderDate),
        DATEPART(QUARTER, soh.OrderDate)
),

RevenueGrowth AS (SELECT
    OrderYear,
    OrderQuarter,
    TotalQuarterlyRevenue,
    LAG(TotalQuarterlyRevenue) OVER(ORDER BY OrderYear, OrderQuarter) AS PreviousQuarterRevenue,
    (TotalQuarterlyRevenue - LAG(TotalQuarterlyRevenue) OVER(ORDER BY OrderYear, OrderQuarter)) AS RevenueChange
FROM RevenueTable)
SELECT *,
    RevenueGrowthPercent = RevenueChange*100 / NULLIF(PreviousQuarterRevenue, 0)
FROM RevenueGrowth
ORDER BY
    OrderYear,
    OrderQuarter

/*
  Insight:
  - Long-term growth trend overall, with sustained growth from Q2/2011 to Q3/2012.
  - Clear seasonal pattern: revenue tends to decline every Q4, indicating seasonality in the business.
  - Notable drop in Q2/2014, likely due to market-side issues or incomplete data for that period.
  - Recommendation: Leverage Q2–Q3 as the primary growth window; plan demand-stimulation or
    production strategies specifically for Q4 underperformance.
*/

-- Q2: Revenue ranking by territory (Sales)
SELECT
    st.Name AS TerritoryName,
    SUM(soh.SubTotal) AS TotalTerritoryRevenue,
    RANK() OVER(
        ORDER BY SUM(soh.SubTotal) DESC
    ) AS RevenueRank
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesTerritory st
    ON soh.TerritoryID = st.TerritoryID
WHERE soh.Status = 5 -- đơn đã hoàn thành
GROUP BY st.Name
ORDER BY RevenueRank

/*
  Insight:
  - Top 3 territories by revenue: Southwest, Canada, Northwest (Western US and Canada).
  - Lower-performing territories: Southeast, UK, France, Northeast, Germany (Eastern US and Europe).
*/



-- Q3: Online vs. Offline order breakdown (Sales)
WITH Ratio AS (SELECT
    CASE
        WHEN SalesPersonID IS NOT NULL THEN 'Offline'
    ELSE 'Online'
    END AS [Category],
    SUM(SubTotal) AS SalesTotal,
    COUNT(SalesOrderID) AS 'OrderCount'
FROM Sales.SalesOrderHeader
GROUP BY 
    (CASE
        WHEN SalesPersonID IS NOT NULL THEN 'Offline'
    ELSE 'Online'
    END)
    )

SELECT
    Category,
    SalesTotal,
    OrderCount,
    CAST(SalesTotal*100.0/SUM(SalesTotal) OVER() AS DECIMAL(10,4)) AS 'SalesRate',
    CAST(OrderCount*100.0/SUM(OrderCount) OVER() AS DECIMAL(10,4))AS 'OrderRate'
FROM Ratio

/*
  Insight:
  - The Online channel accounts for the majority of order volume but carries a much lower average order value.
  - Conversely, the Offline channel has fewer orders but significantly higher order values.
  - This reflects the fundamental behavioral difference between individual (B2C) and business (B2B) customers.
*/


-- Q4: Top 5 customers by revenue contribution, split by customer type (Customer)
WITH SalesByCustomer AS (
SELECT
    CASE
        WHEN soh.SalesPersonID IS NOT NULL
        THEN 'Store'
        ELSE 'Person'
    END AS CustomerType,
    soh.CustomerID,
    SUM(SubTotal) AS TotalSales
FROM Sales.SalesOrderHeader soh
GROUP BY
    CASE
        WHEN soh.SalesPersonID IS NOT NULL
        THEN 'Store'
        ELSE 'Person'
    END,
    soh.CustomerID
),

SalesByCustomer2 AS (
SELECT
    CustomerType,
    CustomerID,
    TotalSales,
    DENSE_RANK() OVER(PARTITION BY CustomerType ORDER BY TotalSales DESC) AS SalesRank,
    CAST (TotalSales*100.0 / SUM(TotalSales) OVER(PARTITION BY CustomerType) AS DECIMAL(10,4)) AS 'SalesRate(%)'
FROM SalesByCustomer
)

SELECT * FROM SalesByCustomer2
WHERE SalesRank <= 5

/*
  Insight:
  - Revenue is highly distributed across the customer base, no single individual or store dominates.
  - This indicates a broad, diversified customer portfolio with no dangerous over-reliance on any one account.
*/



-- Q5: Top 10 most profitable products (Product)
WITH ProductInfo AS(
SELECT
    sod.ProductID,
    pp.StandardCost,
    pp.Name AS ProductName,
    SUM(sod.LineTotal) AS TotalProductSales,
    SUM(sod.OrderQty) AS TotalProductQuantity
FROM Sales.SalesOrderDetail sod
JOIN Production.Product pp
    ON sod.ProductID = pp.ProductID
GROUP BY sod.ProductID, pp.Name, pp.StandardCost
),

ProductProfitInfo AS (
SELECT
    ProductID,
    ProductName,
    TotalProductSales - StandardCost * TotalProductQuantity AS TotalProfit
FROM ProductInfo
)
SELECT TOP 10
    ProductID,
    ProductName,
    TotalProfit,
    CAST (TotalProfit*100.0 / SUM(TotalProfit) OVER () AS DECIMAL(20, 4)) AS 'ProfitRate(%)'
FROM ProductProfitInfo
ORDER BY TotalProfit DESC

/*
  Insight:
  - All top 10 products belong to just two lines: Mountain-200 and Road-150 — showing high profit concentration with limited diversification.
  - Mountain-200 is the dominant line (profit range: $611K–$674K per SKU), with Road-150 as a secondary driver ($406K–$470K).
  - Together, these top 10 SKUs account for approximately 60% of total company profit.
  - Recommendations:
      · Prioritize marketing investment in Mountain-200 and Road-150 to maximize returns.
      · Consider developing new variants/iterations of Mountain-200 given its strong demand.
      · Maintain sufficient stock levels for these 10 SKUs to prevent stockouts.
      · Risk flag: heavy profit dependency on 2 lines — diversification of the product portfolio is needed to hedge against shifts in market demand.
*/

-- Q6a: Vendors with highest rejection rates — overall (Purchasing)
SELECT
    poh.VendorID,
    v.Name,
    SUM(pod.OrderQty) AS TotalOrder,
    SUM(pod.RejectedQty) AS TotalReject,
    CAST(SUM(pod.RejectedQty)*100.0 / SUM(pod.OrderQty) AS DECIMAL(5,2)) AS 'RejectedRate'
FROM Purchasing.PurchaseOrderDetail pod
JOIN Purchasing.PurchaseOrderHeader poh
    ON pod.PurchaseOrderID = poh.PurchaseOrderID
JOIN Purchasing.Vendor v
    ON poh.VendorID = v.BusinessEntityID
WHERE poh.Status = 4 --completed orders only
GROUP BY poh.VendorID, v.Name
ORDER BY SUM(pod.RejectedQty)*100.0 / SUM(pod.OrderQty) DESC

/*
  Insight:
  - Top rejection rates across vendors range from 1.4% to 1.9% — relatively uniform, with no single vendor standing out as significantly worse than the rest.
  - The 4 vendors with the highest rates (Sport Playground, American Bikes, West Junction Cycles, Inline Accessories) are closely clustered — may share a common component type or manufacturing issue.
  - Recommendation: Engage these 4 vendors directly to investigate the root cause.
  - Next step: drill down by ProductID to identify whether the issue is vendor-wide or SKU-specific.
*/

-- Q6b: Vendors with highest rejection rates — drilled down by ProductID (Purchasing)
SELECT
    poh.VendorID,
    v.Name,
    pod.ProductID,
    SUM(pod.OrderQty) AS TotalOrder,
    SUM(pod.RejectedQty) AS TotalReject,
    CAST(SUM(pod.RejectedQty)*100.0 / SUM(pod.OrderQty) AS DECIMAL(5,2)) AS 'RejectedRate'
FROM Purchasing.PurchaseOrderDetail pod
JOIN Purchasing.PurchaseOrderHeader poh
    ON pod.PurchaseOrderID = poh.PurchaseOrderID
JOIN Purchasing.Vendor v
    ON poh.VendorID = v.BusinessEntityID
WHERE poh.Status = 4 -- completed orders only
GROUP BY poh.VendorID, v.Name, pod.ProductID
HAVING SUM(pod.OrderQty) > 5000 -- vendors with total order qty > 5,000 to remove low-volume noise
ORDER BY SUM(pod.RejectedQty)*100.0 / SUM(pod.OrderQty) DESC

/*
  Insight:
  - Custom Frames, Inc. occupies the top 2 spots with rejection rates of 3.45% and 3.19% for product IDs 488 and 481, respectively.
  - Chicago City Saddles ranks 3rd with a 3.14% rejection rate on product ID 913.
  - Overall rejection rates per vendor are relatively similar, but the issues are concentrated in specific SKUs — suggesting the quality problems are process, or component-specific, not vendor-wide.
  - Recommendation: Re-engage high-SKU-rejection vendors to identify whether the issue stems from materials, manufacturing process, or handling.
*/



-- Q7: Products with high revenue but negative profit margin (Product)
WITH Revenue_Profit AS (
    SELECT 
        p.ProductID,
        p.Name AS ProductName,
        SUM(sod.LineTotal) AS Revenue,
        SUM(sod.LineTotal - (sod.OrderQty * p.StandardCost)) AS Profit
    FROM Sales.SalesOrderDetail sod
    JOIN Production.Product p 
        ON sod.ProductID = p.ProductID
    GROUP BY p.ProductID, p.Name
),

Margin AS (
    SELECT *,
        CASE
        WHEN Revenue = 0 THEN 0
        ELSE Profit*100.0/Revenue
        END AS 'ProfitMargin(%)'
    FROM Revenue_Profit
)
SELECT * FROM Margin
WHERE Revenue > (SELECT AVG(Revenue) FROM Revenue_Profit) -- Filter: above-average revenue products with negative profit
AND Profit < 0
ORDER BY Revenue DESC

/*
Insight:
  - The Touring-1000 line has deeply negative profit margins despite generating high revenue —
    indicating it is a core product line (not a secondary accessory), and that the company may
    be misallocating resources toward it.
  - The Road-650 line appears frequently, with Road-650 Red (size 44) at -16.3% — the worst margin
    in this group. The entire Road-650 line needs a full review: raw material sourcing,
    production costs, and any promotional pricing that may be pushing COGS too high.
  - Consideration: whether to continue selling the Road-650 line at all.
  - When the above-average revenue filter is removed, ML Road Frame and HL Road Frame also appear
    with margins of -6.3% to -6.8% — suggesting these frame components face similar cost issues.
  - Overall: the presence of high-revenue, negative-margin products indicates the company may
    be optimizing for top-line growth at the expense of financial efficiency.
*/



-- Q8: Quarterly profit margin — high-profit lines (Mountain-200, Road-150) vs. low-profit lines (Touring-1000, Road-650) (Sales)
WITH Finance AS (    
    SELECT
        DATEPART(YEAR, soh.OrderDate) AS OrderYear,
        DATEPART(QUARTER, soh.OrderDate) AS OrderQuarter,
        p.Name,
        SUM(sod.LineTotal) AS Revenue,
        SUM(sod.OrderQty * p.StandardCost) AS Cost,
        SUM(sod.LineTotal) - SUM(sod.OrderQty * p.StandardCost) AS Profit
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.SalesOrderDetail sod
        ON soh.SalesOrderID = sod.SalesOrderID
    JOIN Production.Product p
        ON sod.ProductID = p.ProductID
    GROUP BY DATEPART(YEAR, soh.OrderDate),
        DATEPART(QUARTER, soh.OrderDate), p.Name

),
ProductType AS(
    SELECT
    *,
        CASE
        WHEN Name LIKE 'Mountain-200%' OR Name LIKE 'Road-150%' THEN 'High-profit Product'
        WHEN Name LIKE 'Touring-1000%' OR Name LIKE 'Road-650%' THEN 'Low-profit Product'
        ELSE 'Other'
        END AS ProductType
    FROM Finance
)
SELECT
    OrderYear,
    OrderQuarter,
    ProductType,
    SUM(Revenue) AS TotalRevenue,
    SUM(Cost) AS TotalCost,
    SUM(Profit) AS TotalProfit,
    CAST(SUM(Profit)*100.0 / SUM(Revenue) AS DECIMAL(8,2)) AS ProfitRate
FROM ProductType
WHERE ProductType LIKE 'High-profit Product' OR ProductType LIKE 'Low-profit Product'
GROUP BY OrderYear, OrderQuarter, ProductType
ORDER BY OrderYear, OrderQuarter, ProductType

/*
  Insight:
  - From Q2/2011 to Q2/2012, the High-profit group's margin declined steadily, while the
    Low-profit group held a range of -13.7% to -11.3% throughout.
  - During this same period, Low-profit group revenue grew rapidly — suggesting the company was
    heavily pushing these loss-making product lines.
  - From Q3/2013 onward, margins improved for both groups. In Q4/2013, the Low-profit group
    turned positive for the first time and continued improving — coinciding with a recovery in
    the Touring-1000 and Road-650 profitability trend.
*/


-- Top reasons for product scrapping (Manufacturing)
SELECT
    SUM(w.ScrappedQty) AS TotalScrappedQty,
    w.ScrapReasonID,
    s.Name
FROM Production.WorkOrder w
JOIN Production.ScrapReason s
    ON w.ScrapReasonID = s.ScrapReasonID
GROUP BY w.ScrapReasonID, s.Name
ORDER BY SUM(w.ScrappedQty) DESC

/*
   Insight:
- Paint process failed is the leading issue, with 1,271 products rejected. This is the most critical problem in the production line, suggesting major technical or environmental gaps in the painting process.
- Other causes such as Trim length too long, Thermoform temperature too low, and Drill size too small are mainly related to machinery issues (cutting machines, thermoforming equipment, and drills).
- Improving the painting stage and performing stricter technical checks on these machines could significantly reduce the number of defective products.
*/