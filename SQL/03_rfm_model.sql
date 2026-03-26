--PART 3: RFM CUSTOMER SEGMENTATION MODEL
WITH Monetary_Raw AS (
SELECT
CustomerID,
SUM(Subtotal) TotalRev,
PERCENT_RANK() OVER(ORDER BY SUM(Subtotal) ASC) AS Percent_Rank_Rev
FROM Sales.SalesOrderHeader
GROUP BY CustomerID),

Monetary_Category AS (
SELECT 
CustomerID,
TotalRev,
CASE
	WHEN Percent_Rank_Rev <= 0.25 THEN 1
	WHEN Percent_Rank_Rev <= 0.5 THEN 2
	WHEN Percent_Rank_Rev <= 0.75 THEN 3
	ELSE 4
END Monetary
FROM Monetary_Raw
),

Frequency_Raw AS (
SELECT
CustomerID,
COUNT(DISTINCT SalesOrderNumber) TotalOrder,
PERCENT_RANK() OVER(ORDER BY COUNT(DISTINCT SalesOrderNumber) ASC) AS Percent_Rank_Order
FROM Sales.SalesOrderHeader
GROUP BY CustomerID),

Frequency_Category AS (
SELECT 
CustomerID,
TotalOrder,
CASE
	WHEN Percent_Rank_Order <= 0.25 THEN 1
	WHEN Percent_Rank_Order <= 0.5 THEN 2
	WHEN Percent_Rank_Order <= 0.75 THEN 3
	ELSE 4
END Frequency
FROM Frequency_Raw
),

Recency_Raw AS (
SELECT
CustomerID,
DATEDIFF(DAY, MAX(OrderDate), '2014-06-30') GapDay,
PERCENT_RANK() OVER(ORDER BY DATEDIFF(DAY, MAX(OrderDate), '2014-06-30')) AS Percent_Rank_Recency
FROM Sales.SalesOrderHeader
GROUP BY CustomerID),

Recency_Category AS (
SELECT 
CustomerID,
GapDay,
CASE
	WHEN Percent_Rank_Recency <= 0.25 THEN 4
	WHEN Percent_Rank_Recency <= 0.5 THEN 3
	WHEN Percent_Rank_Recency <= 0.75 THEN 2
	ELSE 1
END Recency
FROM Recency_Raw
),

Final AS (
SELECT 
a.*,
b.TotalOrder,
b.Frequency,
c.GapDay,
c.Recency
FROM
Monetary_Category a
LEFT JOIN Frequency_Category b ON a.CustomerID = b.CustomerID
LEFT JOIN Recency_Category c ON a.CustomerID = c.CustomerID
),
Final2 AS (
SELECT *,
CONCAT(Recency, Frequency, Monetary) RFM,
CASE
        WHEN CONCAT(Recency, Frequency, Monetary) = '444' THEN 'Best Customer'
        WHEN CONCAT(Recency, Frequency, Monetary) LIKE '4%4' THEN 'Loyal High Value' -- Nhóm giá trị cao (M = 4)
        WHEN CONCAT(Recency, Frequency, Monetary) LIKE '3%4' THEN 'Potential Loyal'
        WHEN CONCAT(Recency, Frequency, Monetary) LIKE '2%4' THEN 'Almost Big Customer'
        WHEN CONCAT(Recency, Frequency, Monetary) LIKE '1%4' THEN 'Lost Big Customer'
        WHEN CONCAT(Recency, Frequency, Monetary) LIKE '1%' THEN 'At Risk' -- Nhóm rủi ro (R thấp)
        WHEN CONCAT(Recency, Frequency, Monetary) LIKE '2%' THEN 'Almost Lost'
        WHEN CONCAT(Recency, Frequency, Monetary) LIKE '4%' THEN 'Recent Customer' -- Nhóm mới mua gần đây
        ELSE 'Other'
END AS Cus_Category
FROM Final
)

SELECT *
INTO #Final2
FROM Final2
--
SELECT * FROM #Final2
--
SELECT 
    Cus_Category,
    COUNT(*) AS NumCustomer,
    CAST(COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM #Final2),0) AS DECIMAL(5,2)) AS PercentCustomer, --tỷ lệ % từng loại khách
    SUM(TotalRev) AS TotalRevenue, --tổng doanh thu theo từng loại khách hàng
    CAST (SUM(TotalRev)*100.0 / NULLIF((SELECT SUM(TotalRev) FROM #Final2),0) AS DECIMAL(5,2)) AS PercentRevenue --% doanh thu theo từng loại kh
FROM #Final2
GROUP BY Cus_Category
ORDER BY TotalRevenue DESC

/*
  RFM Model — Insight Summary:
 
  1. Revenue concentration:
     - "Potential Loyal" and "Best Customer" combined account for 68.19% of total revenue
       despite representing less than 10% of total customers.
 
  2. Potential Loyal (highest priority):
     - This is currently the most valuable group (45.19% of revenue).
     - Recency score = 3, meaning these are high-spending customers who purchased relatively recently.
     - The company must focus on nurturing this segment into "Best Customer" status —
       and prevent them from sliding down to "Almost Big Customer" or worse, "Lost Big Customer."
 
  3. Lost Big Customer (R=1, M=4):
     - Represents 16.09% of historical revenue — a large portion of high-value customers
       that the company has already lost.
     - Strong win-back potential given their demonstrated spending capacity.
 
  4. High-volume, low-value segments (At Risk, Recent Customer, Almost Lost):
     - These three groups together account for over 57% of total customers,
       but contribute only ~5.8% of revenue.
     - They represent low-AOV retail buyers.
     - "At Risk" and "Almost Lost" alone make up ~37.8% of the customer base,
       suggesting significant issues with post-purchase engagement or retail retention strategy.
 
  Recommendations:
  - Build a dedicated loyalty program specifically for "Potential Loyal" and "Best Customer."
  - Launch targeted win-back campaigns for the "Lost Big Customer" segment.
  - Instead of broad acquisition marketing, shift focus toward bundle/combo offers
    to increase AOV for the large-but-low-value retail base — this is more cost-efficient
    than chasing new customers who may end up in the same low-value segments.
*/