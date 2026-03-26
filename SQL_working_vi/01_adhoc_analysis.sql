--PHẦN 1: TRẢ LỜI CÁC CÂU HỎI ADHOC CÓ Ý NGHĨA
--Tình hình doanh thu theo từng quý trong các năm gần đây (Sales)
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

/* Nhận xét: xu hướng tăng trưởng trong dài hạn, đặc biệt trong giai đoạn Q2/2011-Q3/2012 tăng trưởng liên tục
Có quy luật: doanh thu có xu hướng sụt giảm vào Q4 hàng năm, cho thấy tình hình kinh doanh có tính thời vụ
Đặc biệt: Q2/2014 chứng kiến sự sụt giảm mạnh trong doanh thu. Điều này có thể do công ty gặp vấn đề về thị trường, hoặc do dữ liệu chưa cập nhật đầy đủ
Doanh nghiệp cần tận dụng giai đoạn Q2-Q3 để tăng trưởng doanh thu, và cần có chiến lược kích cầu hoặc sản xuất phù hợp cho Q4 khi doanh thu giảm */



--Xếp hạng doanh thu theo từng khu vực (Sales)
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

/*Top 3 thị trường có doanh thu cao nhất là Southwest, Canada, Nortwest (Tây Mỹ và Canada)
Các thị trường có doanh thu thấp hơn là Southeast, UK, France, Northeast, Germany (Đông Mỹ và châu Âu) */



--Tỷ lệ đơn hàng Online và Offline (Sales)
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

/*Kênh Online chiếm tỷ trọng lớn về số lượng đơn hàng nhưng giá trị trung bình mỗi đơn thấp. 
Ngược lại, kênh Offline có số lượng đơn ít hơn nhưng giá trị đơn hàng cao hơn nhiều. 
Điều này phản ánh sự khác biệt giữa hành vi mua của khách hàng cá nhân và khách hàng doanh nghiệp */



--Top 5 khách hàng mua hàng nhiều nhất và % đóng góp doanh thu của họ (Customer) (chia ra theo từng nhóm là khách hàng cá nhân và store)
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

/* Cơ cấu doanh thu khách hàng phân tán. Điều này cho thấy công ty có một tệp khách hàng rất rộng và không bị phụ thuộc vào bất kỳ cá nhân/cửa hàng cụ thể nào.*/


--Top 10 sản phẩm mang lại lợi nhuận (profit) cao nhất (Product)
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

/* Nhận xét: tất cả top 10 mẫu mang lại lợi nhuận lớn nhất đều tập trung ở 2 dòng xe là Mountain-200 và Road-150, cho thấy danh mục sản phẩm có sự tập trung cao, thiếu sự đa dạng hóa trong việc mang lại lợi nhuận
- Có sự chênh lệnh lớn trong profit của dòng Mountain-200 (profit từ 611k-674k) và Road-150 (406k-470k) cho thấy Mountain-200 là sản phẩm chủ đạo
- Tổng % profit của cả top 10 sản phẩm này đạt khoảng 60% profit của công ty, cho thấy phần lớn lợi nhuận công ty phụ thuộc vào chỉ 2 dòng xe này
- Cần đẩy mạnh chiến lược Marketing cho dòng Mountain-200 và Road-150 để gia tăng lợi nhuận. Cân nhắc nghiên cứu thêm nhiều biến thể cho dòng Mountain-200 đang được ưa chuộng này
- Ưu tiên lưu kho cho 10 mẫu sản phẩm này để tránh hết hàng
- Rủi ro doanh thu sụt giảm nếu nhu cầu thị trường thay đổi. Cần nghiên cứu và đa dạng hóa danh mục sản phẩm */



--Các nhà cung cấp (Vendor) có tỷ lệ hàng bị từ chối (Reject) cao nhất (Purchasing)
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
WHERE poh.Status = 4 --Những đơn complete
GROUP BY poh.VendorID, v.Name
ORDER BY SUM(pod.RejectedQty)*100.0 / SUM(pod.OrderQty) DESC

/* Top các vendor có tỷ lệ bị từ chối hàng cao nhất dao động quanh mức 1.4%–1.9%. Điều này cho thấy chất lượng giữa các nhà cung cấp tương đối đồng đều, không có vendor nào có tỷ lệ bị từ chối cao hơn hẳn nhóm còn lại
- 4 vendor có tỷ lệ cao nhất lại tương đối đồng đều, xấp xỉ 1.9%(Sport Playground, American Bikes, West Junction Cycles, Inline Accessories), điều này có thể do 1 nhóm linh kiện đặc thù, hoặc các vendor này có một điểm chung nào đó
- Cần trao đổi lại với 4 vendor này để tìm ra nguyên nhân
- Tiếp tục đào sâu bằng việc select và group by ProductID */

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
WHERE poh.Status = 4 --Những đơn complete
GROUP BY poh.VendorID, v.Name, pod.ProductID
HAVING SUM(pod.OrderQty) > 5000 --chỉ chọn những vendor có số lượng đơn >5000, loại bỏ những vendor cung cấp quá ít gây nhiễu
ORDER BY SUM(pod.RejectedQty)*100.0 / SUM(pod.OrderQty) DESC

/* Custom Frames, Inc. chiếm 2 vị trí đầu bảng với tỷ lệ lỗi là 3.45% và 3.19% cho 2 mã hàng lần lượt là 488 và 481
- Chicago City Saddles có tỷ lệ rejected cao thứ 3 với 3.14% ở mã sản phẩm 913
- Tỷ lệ bị từ chối tổng thể của các vendor không có nhiều khác biệt, nhưng lại tập trung vào một vài mã hàng cụ thể
- Điều này cho thấy vấn đề về chất lượng của công ty có thể bị ảnh hưởng ở 1 số khâu sản xuất cụ thể. Cần làm việc lại với các vendor có tỷ lệ reject trên mỗi mã hàng cao để tìm ra nguyên nhân */




--Top các sản phẩm có doanh thu cao nhưng lợi nhuận thấp (Product)
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
WHERE Revenue > (SELECT AVG(Revenue) FROM Revenue_Profit) --chỉ lấy những sản phẩm mang lại doanh thu trên trung bình
AND Profit < 0
ORDER BY Revenue DESC

/* Dòng Touring-1000 có biên lợi nhuận âm sâu, mặc dù doanh thu mang lại rất lớn. Doanh thu lớn cho thấy đây là 1 trong những sản phẩm chính (không phải sản phẩm phụ đi kèm), điều này chỉ ra khả năng công ty đang tập trung nguồn lực sai sản phẩm
- Dòng xe Road-650 xuất hiện rất nhiều, đặc biệt loại Road-650 Red, 44 có biên lợi nhuận -16.3%, mức âm cao nhất. Công ty cần rà soát lại toàn bộ dòng xe này, từ khâu nhập vật liệu, sản xuất và các chương trình khuyến mãi nào khiến giá vốn bị đẩy lên quá cao
- Biên lợi nhuận của dòng Road-650 nhìn chung không tốt, cần cân nhắc có nên tiếp tục bán dòng xe này nữa hay không
- Bỏ giới hạn "chỉ lấy những sản phẩm mang lại doanh thu trên trung bình" đi, tiếp tục thu được sản phẩm ML Road Frame và HL Road Frame đều có profit margin âm 6.3% đến âm 6.8%. Sản phẩm khung xe này có thể cũng đang gặp vấn đề khiến cho chi phí sản xuất và kinh doanh tăng cao, dẫn đến lợi nhuận âm
- Việc có những sản phẩm doanh thu cao nhưng lợi nhuận âm cho thấy công ty có thể đang tập trung tăng trưởng doanh thu mà chưa tối ưu hiệu quả tài chính */



--Biên lợi nhuận của các dòng sản phẩm mang lại lợi nhuận cao nhất (Mountain-200, Road-150) và các dòng sản phẩm mang lại lợi nhuận thấp nhất (Touring-1000, Road-650) theo từng quý (Sales)
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

/* Từ Q2/2011 đến Q2/2012, biên lợi nhuận của High-profit Product giảm sâu và liên tục, trong khi biên lợi nhuận của Low-profit Product duy trì từ âm 13.7% đến âm 11.3%  
- Cũng trong giai đoạn này, tổng doanh thu của nhóm Low-profit Product tăng rất nhanh, cho thấy công ty đang dồn nguồn lực để đẩy mạnh dòng sản phẩm thuộc nhóm này
- Từ Q3/2013 chứng kiến sự thay đổi: lợi nhuận ở cả 2 nhóm tăng trở lại, đặc biệt Q4/2013 biên lợi nhuận nhóm Low-profit Product lần đầu đạt mức dương và tiếp tục tăng trưởng trở về sau */




--Những lý do khiến sản phẩm bị bỏ nhiều nhất (Manufacturing)
SELECT
    SUM(w.ScrappedQty) AS TotalScrappedQty,
    w.ScrapReasonID,
    s.Name
FROM Production.WorkOrder w
JOIN Production.ScrapReason s
    ON w.ScrapReasonID = s.ScrapReasonID
GROUP BY w.ScrapReasonID, s.Name
ORDER BY SUM(w.ScrappedQty) DESC

/* Paint process failed dẫn đầu với 1.271 sản phẩm bị bỏ, đây là vấn đề nghiêm trọng nhất trong dây chuyền sản xuất. Quy trình sơn có thể đang có lỗ hổng lớn về kỹ thuật hoặc môi trường
- Các nguyên nhân còn lại như Trim length too long, Thermoform temperature too low, Drill size too small chủ yếu do vấn đề máy móc (máy cắt, máy đúc nhiệt và máy khoan)
- Việc cải thiện công đoạn sơn và kiểm tra kỹ thuật của các loại máy móc có thể giảm đáng kể số sản phẩm lỗi */

