--PHẦN 3: MÔ HÌNH TÍNH TOÁN TRÊN SQL
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

/* Nhận xét:Chỉ riêng hai nhóm Potential Loyal và Best Customer đã chiếm tới 68.19% tổng doanh thu dù chỉ chiếm chưa đầy 10% tổng số lượng khách hàng
- Tiềm năng lớn từ nhóm "Potential Loyal": Đây là nhóm khách hàng quan trọng nhất hiện tại (chiếm 45.19% doanh thu). Với điểm Recency = 3, họ là những khách hàng lớn vừa mới mua hàng cách đây không lâu. Công ty cần tập trung chăm sóc để đưa nhóm này lên thành Best Customer, tránh việc để họ rơi xuống nhóm Almost Big Customer hoặc tệ hơn là Lost Big Customer
- Nhóm Lost Big Customer (R=1, M=4) chiếm tỷ trọng doanh thu khá cao (16.09%) trong tổng dữ liệu lịch sử. Điều này cho thấy công ty đã mất một lượng khách tiềm năng có khả năng chi tiêu mạnh
- Các nhóm đông người mua giá trị thấp (At Risk, Recent Customer, Almost Lost): Ba nhóm này cộng lại chiếm hơn 57% số lượng khách hàng nhưng chỉ đóng góp vỏn vẹn khoảng 5.8% doanh thu. Đây là nhóm khách hàng mua lẻ có AOV thấp. Đặc biệt, nhóm At Risk và Almost Lost chiếm tỷ lệ rất cao (~37.8% lượng khách), cho thấy dịch vụ sau bán hàng hoặc chiến lược giữ chân khách lẻ của công ty đang gặp vấn đề
- Công ty cần tập trung tạo chương trình khách hàng thân thiết riêng biệt cho nhóm Potential Loyal và Best Customer
- Tập trung Marketing nhắm mục tiêu vào nhóm Lost Big Customer để lôi kéo họ quay lại
- Thay vì Marketing diện rộng để chạy theo khách mới, công ty cần tập trung vào việc tạo các gói Combo để nâng cao AOV, giúp bù đắp chi phí vận hành cho nhóm khách lẻ vốn đang chiếm số đông nhưng doanh thu thấp */

