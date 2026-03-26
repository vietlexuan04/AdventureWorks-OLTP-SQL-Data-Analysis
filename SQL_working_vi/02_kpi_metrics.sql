--PHẦN 2: TÍNH TOÁN MỘT SỐ CHỈ SỐ KPI CHO CÔNG TY
--Biên lợi nhuận gộp theo từng quý
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

/* Lợi nhuận giảm dần và chạm đáy vào Q2/2012 (-3.11%) và duy trì mức rất thấp (dưới 4%) cho đến tận Q2/2013, mặc dù doanh thu nhìn chung tăng
- Công ty rơi vào tình trạng tăng trưởng nhưng không hiệu quả, một trong những nguyên nhân đến từ việc tập trung nguồn lực vào nhóm sản phẩm mang lại lợi nhuận thấp là Touring-1000 và Road-650 (cũng trong giai đoạn này)
- Từ Q3/2013 đến 2014 lợi nhuận tăng trở lại và đạt đỉnh vào Q2/2014, trùng khớp với việc lợi nhuận từ 2 sản phẩm Touring-1000 và Road-650 đạt mức dương và liên tục tăng */




--Giá trị đơn hàng trung bình AOV theo từng kênh online và offline
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

/* Doanh thu của công ty phụ thuộc lớn vào kênh offline với giá trị đơn hàng cao gấp 20 lần kênh online
Tuy nhiên, kênh online lại là nơi tiếp cận khách hàng cá nhân rộng rãi. Điều này đòi hỏi chiến lược Marketing khác nhau cho 2 kênh: Tập trung chăm sóc khách hàng đại lý offline và tăng giá trị giỏ hàng cho khách hàng lẻ, thông qua việc tạo các combo */



--Tỷ lệ sản phẩm lỗ = Số sản phẩm có lợi nhuận âm / Tổng số sản phẩm
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

/* 56/266 sản phẩm lỗ, chiếm 21.05% là con số lớn trong khi ở phần 1, top 10 sản phẩm (Mountain-200, Road-150) chiếm tới 60% lợi nhuận công ty
- Công ty đang lấy lợi nhuận từ nhóm sản phẩm chủ lực để bù lỗ cho nhóm 20% sản phẩm này
- Tỷ lệ sản phẩm lỗ cao có thể là hệ quả trực tiếp từ việc chi phí phế phẩm được phân bổ vào giá vốn
- Ngoài việc gia tăng doanh thu thông qua các chiến dịch với khách hàng online và offline, công ty cũng cần rà soát lại các sản phẩm lỗ này để có chiến lược kinh doanh/định giá phù hợp, kiểm soát chất lượng sản xuất và tối ưu nhà cung cấp */