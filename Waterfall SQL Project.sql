/* STEP 1: SETUP BUDGET DATA 
-----------------------------------------------------------*/
IF OBJECT_ID('Sales.RevenueBudget', 'U') IS NOT NULL DROP TABLE Sales.RevenueBudget;

CREATE TABLE Sales.RevenueBudget (
    BudgetID INT IDENTITY(1,1) PRIMARY KEY,
    ProductCategoryID INT,
    BudgetDate DATE,
    TargetQty INT,
    TargetRevenue MONEY
);

-- Populate with synthetic targets (2014 data as base)
INSERT INTO Sales.RevenueBudget (ProductCategoryID, BudgetDate, TargetQty, TargetRevenue)
SELECT 
    p.ProductSubcategoryID, 
    DATEFROMPARTS(YEAR(soh.OrderDate), MONTH(soh.OrderDate), 1),
    CAST(SUM(sod.OrderQty) * 1.05 AS INT), -- Target is 5% more units
    SUM(sod.LineTotal) * 1.10             -- Target is 10% more revenue
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
WHERE soh.OrderDate BETWEEN '2014-01-01' AND '2014-12-31'
GROUP BY p.ProductSubcategoryID, YEAR(soh.OrderDate), MONTH(soh.OrderDate);

/* STEP 2: CALCULATE THE WATERFALL (BRIDGE)
-----------------------------------------------------------*/
WITH Actuals AS (
    SELECT 
        p.ProductSubcategoryID,
        DATEFROMPARTS(YEAR(soh.OrderDate), MONTH(soh.OrderDate), 1) AS SalesMonth,
        SUM(sod.OrderQty) AS ActualQty,
        SUM(sod.LineTotal) AS ActualRevenue,
        SUM(sod.LineTotal) / NULLIF(SUM(sod.OrderQty), 0) AS AvgActualPrice
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
    JOIN Production.Product p ON sod.ProductID = p.ProductID
    WHERE soh.OrderDate BETWEEN '2014-01-01' AND '2014-12-31'
    GROUP BY p.ProductSubcategoryID, YEAR(soh.OrderDate), MONTH(soh.OrderDate)
),
BridgeLogic AS (
    SELECT 
        A.SalesMonth,
        sc.Name AS CategoryName,
        B.TargetRevenue AS Budget_StartingPoint,
        A.ActualRevenue AS Actual_EndingPoint,
        (A.ActualRevenue - B.TargetRevenue) AS TotalVariance,
        
        -- Price Effect: (Actual Price - Budget Price) * Actual Qty
        -- (Shows if we sold at higher/lower prices than planned)
        ((A.ActualRevenue / A.ActualQty) - (B.TargetRevenue / B.TargetQty)) * A.ActualQty AS PriceEffect,
        
        -- Volume Effect: (Actual Qty - Budget Qty) * Budget Price
        -- (Shows if we sold more/fewer units than planned)
        (A.ActualQty - B.TargetQty) * (B.TargetRevenue / B.TargetQty) AS VolumeEffect
        
    FROM Actuals A
    JOIN Sales.RevenueBudget B ON A.ProductSubcategoryID = B.ProductCategoryID AND A.SalesMonth = B.BudgetDate
    JOIN Production.ProductSubcategory sc ON A.ProductSubcategoryID = sc.ProductSubcategoryID
)
/* STEP 3: FINAL REPORT FORMATTING
-----------------------------------------------------------*/
SELECT 
    CategoryName,
    FORMAT(Budget_StartingPoint, 'C0') AS [Budget Revenue],
    FORMAT(PriceEffect, 'C0') AS [Price Variance],
    FORMAT(VolumeEffect, 'C0') AS [Volume Variance],
    FORMAT(Actual_EndingPoint, 'C0') AS [Actual Revenue],
    FORMAT(TotalVariance, 'C0') AS [Net Variance],
    CASE WHEN TotalVariance > 0 THEN 'FAVORABLE' ELSE 'UNFAVORABLE' END AS Status
FROM BridgeLogic
ORDER BY TotalVariance ASC;