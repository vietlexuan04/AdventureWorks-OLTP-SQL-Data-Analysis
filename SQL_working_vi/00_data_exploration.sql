-- 1. Kiểm tra: Đơn hàng có SalesPerson (Offline) thì khách hàng là ai?
SELECT 
    COUNT(soh.SalesOrderID) AS OrderCount
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer sc 
    ON soh.CustomerID = sc.CustomerID
WHERE soh.SalesPersonID IS NOT NULL AND sc.StoreID IS NULL
-- kết quả ra 0, chứng tỏ các đơn hàng có SalesPerson (Offline) mà khách hàng không phải là Store thì không tồn tại

-- 2. Kiểm tra: Đơn hàng KHÔNG có Sales Person (Online) thì khách hàng là ai?
SELECT 
    COUNT(soh.SalesOrderID) AS OrderCount
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer sc
    ON soh.CustomerID = sc.CustomerID
WHERE soh.SalesPersonID IS NULL 
  AND sc.StoreID IS NOT NULL
-- kết quả ra 0, chứng tỏ các đơn hàng KHÔNG có SalesPerson (Offline) mà khách hàng là Store thì không tồn tại

/* Qua kiểm tra dữ liệu trên:
Các đơn hàng có SalesPersonID đều là đơn hàng từ khách hàng doanh nghiệp (Store)
Các đơn hàng không có SalesPersonID thì phát sinh từ khách hàng cá nhân (Customer)
Vì vậy, có thể sử dụng SalesPersonID như một biến đại diện để phân loại kênh bán hàng:
Offline (có SalesPerson): B2B
Online (không có SalesPerson): B2C */