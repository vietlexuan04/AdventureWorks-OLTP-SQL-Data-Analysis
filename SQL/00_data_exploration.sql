-- 1. Validation: For orders WITH a SalesPerson (Offline), who are the customers?
SELECT 
    COUNT(soh.SalesOrderID) AS OrderCount
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer sc 
    ON soh.CustomerID = sc.CustomerID
WHERE soh.SalesPersonID IS NOT NULL AND sc.StoreID IS NULL
-- Result is 0, confirming that no Offline orders (with SalesPersonID) exist for non-Store customers

-- 2. Validation: For orders WITHOUT a SalesPerson (Online), who are the customers?
SELECT 
    COUNT(soh.SalesOrderID) AS OrderCount
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer sc
    ON soh.CustomerID = sc.CustomerID
WHERE soh.SalesPersonID IS NULL 
  AND sc.StoreID IS NOT NULL
-- Result is 0, confirming that no Online orders (without SalesPersonID) exist for Store customers

/* 
Data validation summary:
- All orders WITH a SalesPersonID come from business customers (Store)
- All orders WITHOUT a SalesPersonID come from individual customers (Person)
- Therefore, SalesPersonID can be used as a proxy to classify the sales channel:
  Offline (SalesPersonID IS NOT NULL): B2B
  Online  (SalesPersonID IS NULL):     B2C
*/