USE [Business_Demand_Overview_22042024]

SELECT * FROM [dbo].[FACT_InternetSales];

SELECT COUNT (*) FROM [dbo].[FACT_InternetSales];

----------------------------------------------------------------- Creation of Primary Keys--------------------------------------------------------------------------------- 

/**************** FACT_InternetSales table ******************/


-- Checking the sutability of SaleOrderNumber to be declared as primary key
SELECT COUNT([SalesOrderNumber]) FROM [dbo].[FACT_InternetSales];
SELECT COUNT(DISTINCT[SalesOrderNumber]) FROM [dbo].[FACT_InternetSales];
-- As the data is non distinct, SaleOrderNumber is not suitable for primary key


-- Analyzing the sutability of composite key made form ProductKey and SaleOrderNumber as primary key 
SELECT COUNT(CONCAT ([ProductKey],'_',[SalesOrderNumber])) AS count_of_keys FROM [dbo].[FACT_InternetSales];
SELECT COUNT(DISTINCT(CONCAT ([ProductKey],'_',[SalesOrderNumber]))) AS distinct_count_of_keys FROM [dbo].[FACT_InternetSales];
-- As the composite key is disticnt we can use it as primary key.


-- Creation of new column prod_sale_key to fecilitate creation of primary key
ALTER TABLE [dbo].[FACT_InternetSales]
ADD  prod_sale_key VARCHAR(100);
-- This creates a column with all null values


-- inserting values into the new column using UPDATE
UPDATE [dbo].[FACT_InternetSales] 
SET [prod_sale_key] = CONCAT([ProductKey],'_',[SalesOrderNumber])
WHERE [prod_sale_key] IS NULL;
--O/P of concat replaces the nulls


-- Modifying the column to be a NON NLL. This is done to clear path for declaring this col as primary key
ALTER TABLE [dbo].[FACT_InternetSales]
ALTER COLUMN [prod_sale_key] VARCHAR(100) NOT NULL;


-- Declaring the prod_sale_key column as PRIMARY KEY
ALTER TABLE [dbo].[FACT_InternetSales]
ADD CONSTRAINT compkey_prodkey_saleorder PRIMARY KEY ([prod_sale_key]);


/**************** DIM_Customer Table ******************/


ALTER TABLE [dbo].[DIM_Customer]
ALTER COLUMN [CustomerKey] FLOAT NOT NULL ;


ALTER TABLE [dbo].[DIM_Customer]
ADD CONSTRAINT cust_primary_key PRIMARY KEY ([CustomerKey]);


/**************** DIM_Product Table ******************/


ALTER TABLE [dbo].[DIM_Product]
ALTER COLUMN [ProductKey] FLOAT NOT NULL ;


ALTER TABLE [dbo].[DIM_Product]
ADD CONSTRAINT prod_primary_key PRIMARY KEY ([ProductKey]);


/**************** DIM_Calendar Table ******************/

ALTER TABLE [dbo].[DIM_Calendar]
ALTER COLUMN [DateKey] FLOAT NOT NULL;

ALTER TABLE [dbo].[DIM_Calendar]
ADD CONSTRAINT date_primary_key PRIMARY KEY ([DateKey]);


/**************** SalesBudget Table ******************/

ALTER TABLE [dbo].[SalesBudget]
ALTER COLUMN [Budget_Date_Key] FLOAT NOT NULL

ALTER TABLE [dbo].[SalesBudget]
ADD CONSTRAINT budget_primary_key PRIMARY KEY ([Budget_Date_Key])



----------------------------------------------------------------- Connecting the Tables -------------------------------------------------------------------- 

ALTER TABLE [dbo].[FACT_InternetSales]
ADD CONSTRAINT FK_IntSales_ref_cust FOREIGN KEY ([CustomerKey]) REFERENCES [dbo].[DIM_Customer]([CustomerKey]);


ALTER TABLE [dbo].[FACT_InternetSales]
ADD CONSTRAINT FK_IntSales_ref_prod FOREIGN KEY ([ProductKey]) REFERENCES [dbo].[DIM_Product]([ProductKey]);


ALTER TABLE [dbo].[FACT_InternetSales]
ADD CONSTRAINT FK_IntSales_ref_Calend FOREIGN KEY ([OrderDateKey]) REFERENCES [dbo].[DIM_Calendar]([DateKey]);


ALTER TABLE [dbo].[SalesBudget]
ADD CONSTRAINT FK_Budget_ref_Calend FOREIGN KEY ([Budget_Date_Key]) REFERENCES [dbo].[DIM_Calendar]([DateKey]);



----------------------------------------------------------------- Preprocessing - Creating Date Columns in Fact Table -------------------------------------------------------------------- 


--Checking the conversion
SELECT 
		[OrderDateKey],
		CONVERT(date,CAST(CAST([OrderDateKey] AS INT) AS VARCHAR(8)), 112) As OrderDate,
		[DueDateKey],
		CONVERT(date,CAST(CAST([DueDateKey] AS INT) AS VARCHAR(8)), 112) As DueDate,
		[ShipDateKey],
		CONVERT(date,CAST(CAST([ShipDateKey] AS INT) AS VARCHAR(8)), 112) As ShipDate
FROM [dbo].[FACT_InternetSales];


-- Adding new columns
ALTER TABLE [FACT_InternetSales]
ADD OrderDate DATE,DueDate DATE,ShipDate DATE;


-- Inserting values into date column	 
UPDATE [dbo].[FACT_InternetSales]
SET [OrderDate] = CONVERT(date,CAST(CAST([OrderDateKey] AS INT) AS VARCHAR(8)), 112),
	[DueDate] = CONVERT(date,CAST(CAST([DueDateKey] AS INT) AS VARCHAR(8)), 112),
	[ShipDate] = CONVERT(date,CAST(CAST([ShipDateKey] AS INT) AS VARCHAR(8)), 112);



----------------------------------------------------------------- Preprocessing - Replacing the NULL text with NULL values in Product Table -------------------------------------------------------------------- 


UPDATE  [dbo].[DIM_Product]
SET [Sub Category] = null
WHERE [Sub Category] = 'NULL'


UPDATE  [dbo].[DIM_Product]
SET [Product Category] = null
WHERE [Product Category] = 'NULL'


UPDATE [dbo].[DIM_Product] 
SET 
[Product Color] = CASE WHEN [Product Color] = 'NA' THEN NULL ELSE [Product Color] END,
[Product Size] = CASE WHEN [Product Size] = 'NULL' THEN NULL ELSE [Product Size] END,
[Product Line] = CASE WHEN [Product Line] = 'NULL' THEN NULL ELSE [Product Line] END,
[Product Model Name] = CASE WHEN [Product Model Name] = 'NULL' THEN NULL ELSE [Product Model Name] END,
[Product Description] = CASE WHEN [Product Description] = 'NULL' THEN NULL ELSE [Product Description] END



------------------------------------------------------------------------ Total Transactions and Sales_Amount Analysis WRT TimeLine ----------------------------------------------------------------------------------------- 

/*************** Total Transactions and Total Sales Amount ************/
SELECT	COUNT(DISTINCT ([SalesOrderNumber])) AS Total_Transactions,
		SUM([SalesAmount]) As Total_Sale_Amount
FROM [dbo].[FACT_InternetSales] ;


/*************** Total Transactions and Sale Amount distrubution across years ************/
SELECT 	DATEPART(YEAR , [OrderDate]) AS Transaction_Year,
		COUNT(DISTINCT ([SalesOrderNumber])) AS TotalTransactions,
		SUM([SalesAmount])As Total_Sale_Amount
FROM [dbo].[FACT_InternetSales]
GROUP BY DATEPART(YEAR , [OrderDate]);


/*************** Total Transactions and Sale_Amount distrubution across years and months ************/
SELECT 	DATEPART(YEAR,[OrderDate]) AS Transaction_Year,
		DATEPART(MONTH,[OrderDate]) AS Transaction_Month,
		COUNT(DISTINCT([SalesOrderNumber])) AS MonthWise_Transactions,
		SUM([SalesAmount])As MonthWise_SaleAmount
FROM  [dbo].[FACT_InternetSales]
GROUP BY DATEPART(YEAR,[OrderDate]),DATEPART(MONTH,[OrderDate])
ORDER BY Transaction_Year,Transaction_Month;


/*************** Month On Month change in Transactions and Sales_Amount ************/
WITH Distribution_Analysis As 
(
	SELECT 	tb1.Transaction_Year,tb1.Transaction_Month,tb1.Currrent_Month_Transactions,
			LAG(Currrent_Month_Transactions,1) OVER(ORDER BY Transaction_Year, Transaction_Month) AS Previous_Month_Transactions,
			tb1.Current_Month_Sale_Amount,
			LAG(Current_Month_Sale_Amount,1) OVER(ORDER BY Transaction_Year, Transaction_Month) Previous_Month_Sale_Amount
	FROM 
		(
			SELECT 	DATEPART(YEAR,[OrderDate]) AS Transaction_Year,
					DATEPART(MONTH,[OrderDate]) AS Transaction_Month,
					CAST(COUNT(DISTINCT([SalesOrderNumber]))AS DECIMAL (10,2)) AS Currrent_Month_Transactions,
					SUM([SalesAmount])As Current_Month_Sale_Amount
			FROM  [dbo].[FACT_InternetSales]
			GROUP BY DATEPART(YEAR,[OrderDate]),DATEPART(MONTH,[OrderDate])
		 ) AS tb1
)
SELECT 	Distribution_Analysis.Transaction_Year,
		Distribution_Analysis.Transaction_Month,

		Distribution_Analysis.Currrent_Month_Transactions AS MonthWise_Transactions,
		CAST ( ((Currrent_Month_Transactions - Previous_Month_Transactions)/Previous_Month_Transactions) * 100 AS DECIMAL(5,2)) AS Transactions_MOM_Change,
		
		Distribution_Analysis.Current_Month_Sale_Amount AS MonthWise_Sale_Amount,
		((Current_Month_Sale_Amount - Previous_Month_Sale_Amount)/Previous_Month_Sale_Amount)*100 AS SaleAmount_MOM_Change
		
FROM Distribution_Analysis


/*************** Transactions - Same Month Previous Year  ************/
WITH trans_2019 AS 
		(
			SELECT 
					dt.[Year],
					dt.[MonthNo],
					dt.[Month],
					CAST(COUNT(DISTINCT(int_sls.[SalesOrderNumber])) AS DECIMAL(10,2)) AS Monthly_Transactions_2019
			FROM [dbo].[FACT_InternetSales] AS int_sls LEFT JOIN  [dbo].[DIM_Calendar] AS dt on int_sls.OrderDateKey = dt.DateKey
			WHERE dt.[Year] = 2019
			GROUP BY dt.[Year],dt.[MonthNo],dt.[Month]
		),
trans_2020 AS
		(
			SELECT 
					dt.[Year],
					dt.[MonthNo],
					CAST(COUNT(DISTINCT(int_sls.[SalesOrderNumber]))AS DECIMAL(10,2)) AS Monthly_Transactions_2020
			FROM [dbo].[FACT_InternetSales] AS int_sls LEFT JOIN  [dbo].[DIM_Calendar] AS dt on int_sls.OrderDateKey = dt.DateKey
			WHERE dt.[Year] = 2020
			GROUP BY dt.[Year],dt.[MonthNo]
		)
SELECT	trans_2019.MonthNo,
		trans_2019.[Month],
		trans_2019.Monthly_Transactions_2019,
		trans_2020.Monthly_Transactions_2020,
		CAST(((trans_2020.Monthly_Transactions_2020 - trans_2019.Monthly_Transactions_2019)/Monthly_Transactions_2019) * 100 AS DECIMAL (10,2)) AS Percentage_Change
FROM trans_2019 INNER JOIN trans_2020 ON trans_2019.MonthNo = trans_2020.MonthNo


/*************** Sale Amount - Same Month Previous Year Comparision  ************/
WITH sls_2019 AS
		(
			SELECT 
					dt.[Year],
					dt.[MonthNo],
					dt.[Month],
					SUM(int_sls.[SalesAmount]) AS Monthly_SalesAmount_2019
			FROM [dbo].[FACT_InternetSales] AS int_sls LEFT JOIN [dbo].[DIM_Calendar] AS dt ON int_sls.OrderDateKey = dt.DateKey
			WHERE dt.[Year] = 2019
			GROUP BY dt.[Year],dt.[MonthNo],dt.[Month]
		),
sls_2020 AS 
		(
			SELECT 	dt.[Year],
					dt.[MonthNo],
					dt.[Month],
					SUM(int_sls.[SalesAmount]) AS Monthly_SalesAmount_2020
			FROM [dbo].[FACT_InternetSales] AS int_sls LEFT JOIN [dbo].[DIM_Calendar] AS dt ON int_sls.OrderDateKey = dt.DateKey
			WHERE dt.[Year] = 2020
			GROUP BY dt.[Year],dt.[MonthNo],dt.[Month]
		)
SELECT 	sls_2019.MonthNo,
		sls_2019.Month,
		sls_2019.Monthly_SalesAmount_2019,
		sls_2020.Monthly_SalesAmount_2020,
		((sls_2020.Monthly_SalesAmount_2020 - sls_2019.Monthly_SalesAmount_2019)/sls_2019.Monthly_SalesAmount_2019)* 100 AS Percentage_Change
FROM sls_2019 INNER JOIN sls_2020 ON sls_2019.MonthNo = sls_2020.MonthNo


------------------------------------------------------------------------ Comparison of Sales Amount and Budget ----------------------------------------------------------------------------------------- 


/*************** Table(View) of the sales and budget Combined ************/
CREATE VIEW  Sales_and_Budget_Comparison
AS
	WITH Sales_Amount_cte AS
	(
		SELECT 
				dt_tbl.Year,
				dt_tbl.MonthNo,
				CONCAT(dt_tbl.Year,'_',dt_tbl.MonthNo) AS year_month,
				dt_tbl.Month,
				SUM(sls_tbl.SalesAmount) AS Monthly_SalesAmount
		FROM FACT_InternetSales AS sls_tbl LEFT JOIN DIM_Calendar AS dt_tbl ON sls_tbl.OrderDateKey = dt_tbl.DateKey
		GROUP BY dt_tbl.Year,dt_tbl.MonthNo,dt_tbl.Month
	),
	Budget_cte AS
	(
		SELECT 
				dt_tbl.Year,
				dt_tbl.MonthNo,
				CONCAT(dt_tbl.Year,'_',dt_tbl.MonthNo) AS year_month,
				dt_tbl.Month,
				bgt_tbl.Budget
		FROM SalesBudget AS bgt_tbl LEFT JOIN DIM_Calendar AS dt_tbl ON bgt_tbl.Budget_Date_Key = dt_tbl.DateKey
	)
SELECT 	Sales_Amount_cte.Year,
		Sales_Amount_cte.MonthNo,
		Sales_Amount_cte.Month,
		Sales_Amount_cte.year_month,
		Sales_Amount_cte.Monthly_SalesAmount,
		Budget_cte.Budget,
		(Sales_Amount_cte.Monthly_SalesAmount/Budget_cte.Budget) AS SaleAmount_vs_Budget
FROM Sales_Amount_cte FULL JOIN Budget_cte ON Sales_Amount_cte.year_month = Budget_cte.year_month;


/*************** Sales and Budget Comparison over time ************/
SELECT * FROM Sales_and_Budget_Comparison 
ORDER BY COALESCE (Year,MonthNo,2022),MonthNo;
-- SaleAmount_vs_Budget Column column explains how much Sale made for evry unit of amount spent across different months. 
-- This metric is indicating the efficiency of system in conveting the input which is budget into sales over different months.


/*************** Overall Sales and Budget Comparison ************/
SELECT SUM([Monthly_SalesAmount])/SUM([Budget]) AS Total_Sale_vs_TotalBudget
FROM Sales_and_Budget_Comparison
WHERE [Monthly_SalesAmount]>0 AND [Budget]>0
-- This values compares sales with budget as a whole (Over the period where budget data is available).
-- This indicates On an Average how much sale is generated for every unit of budget.
-- The O/P conveys that the company is generating ~1.02 units of sale for every unit of budget.


------------------------------------------------------------------------------------- Analysis of Customers ------------------------------------------------------------------------------------------------------------- 


/*************** Total Customers available on market places ************/
SELECT COUNT([CustomerKey]) AS Total_Customers
FROM DIM_Customer;


/*************** Customer Distribution wrt Gender ************/
SELECT 
		*,
		CAST((Customer_Count) *100 / SUM(Customer_Count) OVER() AS DECIMAL(5,2)) AS Percentage_Distribution
FROM
	(
		SELECT	DIM_Customer.Gender,
				COUNT(DIM_Customer.CustomerKey) AS Customer_Count
		FROM DIM_Customer
		GROUP BY DIM_Customer.Gender
	) AS tb1
-- O/P indicates that the distribution of customers wrt gender is almost equal.



/*************** Total cities Available in Data ************/
SELECT 
	COUNT(DISTINCT(DIM_Customer.[Customer City])) AS Total_Cities
FROM DIM_Customer;


/*************** Customer Distribution across cities ************/
SELECT 
		*,
		CAST (tb1.Customer_Count*100/SUM(Customer_Count) OVER () AS DECIMAL(10,8)) As Percentage_Contribution
FROM 
	(
		SELECT 	DIM_Customer.[Customer City],
				CAST(COUNT(DIM_Customer.CustomerKey) AS DECIMAL(5,2))AS Customer_Count 
		FROM DIM_Customer
		GROUP BY DIM_Customer.[Customer City]
	) AS tb1
ORDER BY tb1.[Customer City];


/*************** Top 10 Cities with highest cutomers ************/
SELECT TOP(10)
			DIM_Customer.[Customer City],
			CAST(COUNT(DIM_Customer.CustomerKey) AS DECIMAL(5,2))AS Customer_Count 
	FROM DIM_Customer
	GROUP BY DIM_Customer.[Customer City]
	ORDER BY Customer_Count DESC;


/*************** Segmentation of cities basing on the count of customers ************/
WITH Customer_City_Dist_CTE
AS
	(
		SELECT	*,
				CASE 
					WHEN Customer_Count >=300 THEN 'Customer Count Above 300'
					WHEN Customer_Count >= 200 AND Customer_Count < 300 THEN 'Cutomer Count Between 200 and 300'
					WHEN Customer_Count<200 AND Customer_Count >= 150 THEN 'Customers Between 150 and 200'
					WHEN Customer_Count < 150 AND Customer_Count >= 100 THEN 'Customers Between 100 and 150'
					WHEN Customer_Count < 100 AND Customer_Count >= 50 THEN 'Customers Between 50 and 100'
					ELSE 'Customer Count Below 50'
					END AS Customer_Segments
		FROM (
				SELECT	DIM_Customer.[Customer City],
						CAST(COUNT(DIM_Customer.CustomerKey) AS DECIMAL(5,2))AS Customer_Count 
				FROM DIM_Customer
				GROUP BY DIM_Customer.[Customer City]
			) AS tb1
	)

SELECT 	Customer_City_Dist_CTE.Customer_Segments,
		COUNT(Customer_City_Dist_CTE.[Customer City]) AS City_Count,
		SUM(Customer_City_Dist_CTE.Customer_Count) As Total_Customers
FROM Customer_City_Dist_CTE
GROUP BY Customer_City_Dist_CTE.Customer_Segments
ORDER BY Total_Customers DESC ;
-- Created Column containing Segments basing on the count of customers available in the city.
-- The o/p is indicates how many cities fall into a particular segment and total customers available in that city.


------------------------------------------------------------------------------------- Analysis of Products ------------------------------------------------------------------------------------------------------------- 


/**************** Total Product_Categories, Sub_Categories and Products ******************/

SELECT	COUNT(DISTINCT([Product Category])) AS Total_Categories,
		COUNT(DISTINCT([Sub Category])) AS Total_SubCatrgories,
		COUNT([ProductKey]) AS Total_Products
FROM [dbo].[DIM_Product];


/**************** Product and sub_category count distribution *******************/
SELECT	[Product Category],
		COUNT(DISTINCT([Sub Category])) AS SubCategory_count,
		COUNT([ProductKey]) AS Product_Count
FROM  [dbo].[DIM_Product]
GROUP BY [Product Category]
ORDER BY COALESCE([Product Category],'zzz') ;


/****************** Product count distribution among Categories and Sub Categories ******************/
SELECT DIM_Product.[Product Category],DIM_Product.[Sub Category],COUNT(DIM_Product.ProductKey) AS product_count
FROM DIM_Product
GROUP BY DIM_Product.[Product Category],DIM_Product.[Sub Category]
ORDER BY COALESCE (DIM_Product.[Product Category],'zzz')


------------------------------------------------------------------------------------Sales and Customer Analysis Combined -----------------------------------------------------------------------------------------------------

CREATE VIEW Sales_Customer_view AS
SELECT 	sls_tbl.SalesOrderNumber,
		sls_tbl.OrderDateKey,
		sls_tbl.CustomerKey,
		sls_tbl.SalesAmount,
		cust_tbl.[Full Name] AS Cutomer_Name,
		cust_tbl.Gender,
		cust_tbl.[Customer City]
FROM [dbo].[FACT_InternetSales] as sls_tbl LEFT JOIN [dbo].[DIM_Customer] AS cust_tbl ON sls_tbl.CustomerKey = cust_tbl.CustomerKey;


/****************** Top 10 customers basing on Total_SaleAmount ******************/
SELECT TOP(10)
		Sales_Customer_view.CustomerKey,
		Sales_Customer_view.Cutomer_Name,
		SUM(Sales_Customer_view.SalesAmount) AS Total_SaleAmount,
		COUNT(DISTINCT(Sales_Customer_view.SalesOrderNumber)) AS Total_Transactions
FROM [dbo].[Sales_Customer_view]
GROUP BY Sales_Customer_view.CustomerKey,Sales_Customer_view.Cutomer_Name
ORDER BY Total_SaleAmount DESC,CustomerKey DESC


/****************** Top 10 Customers basing on Total_Transactions******************/
SELECT TOP(10)
		Sales_Customer_view.CustomerKey,
		Sales_Customer_view.Cutomer_Name,
		COUNT(DISTINCT(Sales_Customer_view.SalesOrderNumber)) AS Total_Transactions,
		SUM(Sales_Customer_view.SalesAmount) AS Total_SaleAmount
FROM [dbo].[Sales_Customer_view]
GROUP BY Sales_Customer_view.CustomerKey,Sales_Customer_view.Cutomer_Name
ORDER BY Total_Transactions DESC,CustomerKey DESC 
/*Customers with top sale amount have made very less transactions when compared to the customer with highest number of transactions. 
Hence we can conclude that Total_Transactions made by customer is not impacting Total_SaleAmount */
 
 
 /*************** Customers who never made a purchase(inactive customers) ************/
SELECT DIM_Customer.CustomerKey
FROM [dbo].[DIM_Customer]

EXCEPT

SELECT CustomerKey
FROM
(
	SELECT Sales_Customer_view.Cutomer_Name,Sales_Customer_view.CustomerKey,SUM(Sales_Customer_view.SalesAmount) AS Total_SaleAmount
	FROM [dbo].[Sales_Customer_view]
	GROUP BY Sales_Customer_view.Cutomer_Name, Sales_Customer_view.CustomerKey
) AS tb1


 /****************** Distribution of sale_amount and Total_Transactions interms of Gender ******************/
SELECT	*,
		tb1.Total_SaleAmount*100 /SUM(tb1.Total_SaleAmount) OVER() AS Percentage_ofTotal_SaleAmount
FROM 
	(
		 SELECT Sales_Customer_view.Gender,
				COUNT(DISTINCT(Sales_Customer_view.SalesOrderNumber)) AS Transaction_Count,
				SUM(Sales_Customer_view.SalesAmount) AS Total_SaleAmount 
		 FROM [dbo].[Sales_Customer_view]
		 GROUP BY Sales_Customer_view.Gender
	 ) AS tb1
-- O/P is indicating that Gender has no influence on Total_Transactions and Total_SaleAmount 


/*************** Total cities with active customers ************/
SELECT COUNT (DISTINCT Sales_Customer_view.[Customer City]) AS active_cities_count
FROM Sales_Customer_view


/****************** Top 10 Cities Basing on Sale_Amount ******************/
SELECT	*,
		(Total_SaleAmount*100/(SELECT SUM([Sales_Customer_view].SalesAmount)
							FROM [dbo].[Sales_Customer_view])) AS Percentage_of_Total_SaleAmount

FROM
	(
		SELECT  TOP(10)
				Sales_Customer_view.[Customer City],
				SUM(Sales_Customer_view.SalesAmount) AS Total_SaleAmount
		FROM Sales_Customer_view
		GROUP BY Sales_Customer_view.[Customer City]
		ORDER BY Total_SaleAmount DESC
	) AS tb2;
-- Note: The Total_SaleAmount considered for percentage calculation is not SaleAmount of top 10 cities. Its the Total Sale amount over entire data.




/****************** Top 10 Cities Basing on Total Transactions ******************/
SELECT  TOP(10)
		Sales_Customer_view.[Customer City],
		COUNT(DISTINCT(Sales_Customer_view.SalesOrderNumber)) AS Total_Transactions
FROM Sales_Customer_view
GROUP BY Sales_Customer_view.[Customer City]
ORDER BY Total_Transactions DESC;
-- Note: Only 3 Cities(London,Paris,Berlin) are common in the top 10 list basing on SaleAmount and Transactions 


/****************** New customer added every year ******************/
SELECT tb1.First_purchase_Year,COUNT(tb1.CustomerKey) AS New_Customers_Count 
FROM 
	(
		SELECT	sls_cust_tbl.CustomerKey,
				MIN(dt_tbl.Date) AS First_purchase_Date,
				DATEPART(YEAR,MIN(dt_tbl.Date)) AS First_purchase_Year
		FROM 
		[dbo].[Sales_Customer_view] AS sls_cust_tbl LEFT JOIN DIM_Calendar AS dt_tbl ON sls_cust_tbl.OrderDateKey = dt_tbl.DateKey
		GROUP BY sls_cust_tbl.CustomerKey
	) AS tb1
GROUP BY tb1.First_purchase_Year
ORDER BY tb1.First_purchase_Year ASC;
-- O/P Indicates that we have 14461 new customers added in the year 2020 (We cannot comment on the data of 2020 as we dont have previous date)
-- For year 2021 till the date considered there were 506 new customers added on to platform.


 /****************** Customer churn every year ******************/
SELECT tb1.Last_purchase_Year,COUNT(tb1.CustomerKey) AS Customer_Count
FROM 
	(
		SELECT sls_cust_tbl.CustomerKey,
				MIN(dt_tbl.Date) AS First_purchase_Date,
				DATEPART(YEAR,MAX(dt_tbl.Date)) AS Last_purchase_Year
		FROM 
		[dbo].[Sales_Customer_view] AS sls_cust_tbl LEFT JOIN DIM_Calendar AS dt_tbl ON sls_cust_tbl.OrderDateKey = dt_tbl.DateKey
		GROUP BY sls_cust_tbl.CustomerKey
	) AS tb1
GROUP BY tb1.Last_purchase_Year
ORDER BY tb1.Last_purchase_Year;
--O/P The platform has lost 287 customers from 2019 to 2020. Could not comment on 2020-2021 as the data is not available


------------------------------------------------------------------------------------Sales and product Analysis Combined -----------------------------------------------------------------------------------------------------

CREATE VIEW Sales_Product_view AS
SELECT	sls_tbl.SalesOrderNumber,
		sls_tbl.OrderDateKey,
		sls_tbl.SalesAmount,
		prod_tbl.ProductKey,
		prod_tbl.[Product Category],
		prod_tbl.[Sub Category],
		prod_tbl.[Product Name],
		prod_tbl.[Product Status]
FROM [dbo].[FACT_InternetSales] as sls_tbl LEFT JOIN [dbo].[DIM_Product] AS prod_tbl ON sls_tbl.ProductKey = prod_tbl.ProductKey;


/****************** Product Sale distribution across Category ******************/
SELECT	tb1.[Product Category],
		tb1.Units_Sold,
		ROUND((Units_Sold*100/SUM(Units_Sold) OVER()),2) AS Percent_Units_Sold,
		tb1.Total_SaleAmount,
		ROUND((Total_SaleAmount*100/SUM(Total_SaleAmount) OVER()),2) AS Percent_SaleAmount,
		ROUND((tb1.Total_SaleAmount/tb1.Units_Sold),2) AS SaleAmount_vs_UnitsSold
FROM
	(
		SELECT	Sales_Product_view.[Product Category],
				CAST(COUNT(Sales_Product_view.SalesOrderNumber) AS FLOAT)  AS Units_Sold,
				SUM(Sales_Product_view.SalesAmount) As Total_SaleAmount
		FROM [dbo].[Sales_Product_view]
		GROUP BY Sales_Product_view.[Product Category]
	) AS tb1
ORDER BY tb1.[Product Category]
-- With 22% of total units sold, Product Category BIKES is contributing 95% of total Sale amount even
-- The Percentage values are indicating that there is not direct relation b/w units sold and sale amount
-- The metric SaleAmount_vs_UnitsSold indicated how much sale we are generating for every unit of respective Product_Category sold


 /******************  Top 3 Sub_Categories in every Category interms of SaleAmount ******************/
 SELECT *
 FROM
	(
		SELECT 	tb1.[Product Category],
				tb1.[Sub Category],
				tb1.Total_SaleAmount,
				ROUND((Total_SaleAmount*100/SUM(Total_SaleAmount) OVER()),2) AS Percent_SaleAmount,
				RANK() OVER (PARTITION BY tb1.[Product Category] ORDER BY tb1.Total_SaleAmount DESC) AS SubCategory_Rank
		FROM
			(
				SELECT	Sales_Product_view.[Product Category],
						Sales_Product_view.[Sub Category],
						SUM(Sales_Product_view.SalesAmount) As Total_SaleAmount
				FROM [dbo].[Sales_Product_view]
				GROUP BY Sales_Product_view.[Product Category],Sales_Product_view.[Sub Category]
			) AS tb1
	) AS tb2
WHERE tb2.SubCategory_Rank IN (1,2,3)
-- The O/P gives top 3 Sub_Categories in every Category in terms of SaleAmount 


 /****************** Top 5 Products interms of SaleAmount  ******************/
SELECT tb2.[Product Category],tb2.[Product Name],tb2.Sale_Amount,tb2.Rank_SubCategory_Level
FROM 
	(
		SELECT *,
				RANK() OVER (PARTITION BY tb1.[Product Category] ORDER BY tb1.Sale_Amount DESC) AS Rank_SubCategory_Level
		FROM
			(
				SELECT	Sales_Product_view.[Product Category],
						Sales_Product_view.[Product Name],
						SUM(Sales_Product_view.SalesAmount) AS Sale_Amount
				FROM [dbo].[Sales_Product_view]
				GROUP BY Sales_Product_view.[Product Category],Sales_Product_view.[Product Name]
			) AS tb1
	) AS tb2
WHERE tb2.Rank_SubCategory_Level IN(1,2,3,4,5)


/****************** Total Unsold Products on Market Place ******************/
SELECT 
	(SELECT COUNT(DISTINCT(DIM_Product.ProductKey)) FROM DIM_Product) AS Available_Products,
	(SELECT COUNT(DISTINCT([dbo].[Sales_Product_view].ProductKey))  FROM[dbo].[Sales_Product_view]) AS Products_Sold,
	((SELECT COUNT(DISTINCT(DIM_Product.ProductKey)) FROM DIM_Product) -(SELECT COUNT(DISTINCT([dbo].[Sales_Product_view].ProductKey)) FROM[dbo].[Sales_Product_view])) AS Unsold_Products
-- Out of all the Available products on market place 473 products are left unsold


/****************** Unsold Products Status ******************/
WITH unsold_prod_cte AS
(
SELECT DISTINCT DIM_Product.ProductKey AS prod_key ,DIM_Product.[Product Status] FROM DIM_Product
EXCEPT
SELECT DISTINCT Sales_Product_view.ProductKey AS prod_key,Sales_Product_view.[Product Status] FROM [dbo].[Sales_Product_view]
)
SELECT 
		unsold_prod_cte.[Product Status],
		COUNT(unsold_prod_cte.prod_key) AS count_Unsold_Products,
		ROUND((CAST(COUNT(unsold_prod_cte.prod_key) AS FLOAT) *100)/SUM(COUNT(unsold_prod_cte.prod_key)) over(),2) AS Percentage_Distribution
FROM unsold_prod_cte
GROUP BY unsold_prod_cte.[Product Status]
-- out of all the unsold products ~64% are active products


CREATE VIEW complete_view AS 

SELECT 
		int_tbl.OrderDateKey,int_tbl.SalesOrderNumber,int_tbl.SalesAmount, -- sales table columns
		cust_tbl.CustomerKey,cust_tbl.[Full Name] AS cust_FullName,cust_tbl.Gender,cust_tbl.[Customer City], -- customer table columns
		prod_tbl.ProductKey,prod_tbl.[Product Category],prod_tbl.[Sub Category],prod_tbl.[Product Name], -- product table columns
		dt_tbl.Date AS Order_Date
FROM FACT_InternetSales AS int_tbl 
LEFT JOIN DIM_Customer AS cust_tbl ON int_tbl.CustomerKey = cust_tbl.CustomerKey 
LEFT JOIN DIM_Product AS prod_tbl ON int_tbl.ProductKey = prod_tbl.ProductKey 
LEFT JOIN DIM_Calendar AS dt_tbl ON int_tbl.OrderDateKey = dt_tbl.DateKey

/****************** Influence of Gender on SaleAmount across Products_Categories ******************/
WITH Female_tbl AS
(
	SELECT complete_view.Gender,complete_view.[Product Category],SUM(complete_view.SalesAmount) AS Total_SaleAmount_Female
	FROM complete_view
	GROUP BY complete_view.Gender,complete_view.[Product Category]
	HAVING complete_view.Gender = 'Female'
),
Male_tbl AS
(
	SELECT complete_view.Gender,complete_view.[Product Category],SUM(complete_view.SalesAmount) AS Total_SaleAmount_Male
	FROM complete_view
	GROUP BY complete_view.Gender,complete_view.[Product Category]
	HAVING complete_view.Gender = 'Male'
)
SELECT	Female_tbl.[Product Category],
		Female_tbl.Total_SaleAmount_Female,
		Male_tbl.Total_SaleAmount_Male,
		Female_tbl.Total_SaleAmount_Female/Male_tbl.Total_SaleAmount_Male AS Ratio_Female_VS_Male
FROM Female_tbl INNER JOIN Male_tbl ON Female_tbl.[Product Category] =Male_tbl.[Product Category]

 -- Results indicating that Gender is not a significant factor in selection of products


 /****************** Influence of Gender on SaleAmount across Products_SubCategories ******************/
 WITH Female_tbl AS
(
	SELECT complete_view.Gender,complete_view.[Product Category],complete_view.[Sub Category],SUM(complete_view.SalesAmount) AS Total_SaleAmount_Female
	FROM complete_view
	GROUP BY complete_view.Gender,complete_view.[Product Category],complete_view.[Sub Category]
	HAVING complete_view.Gender = 'Female'
),
Male_tbl AS
(
	SELECT complete_view.Gender,complete_view.[Product Category],complete_view.[Sub Category],SUM(complete_view.SalesAmount) AS Total_SaleAmount_Male
	FROM complete_view
	GROUP BY complete_view.Gender,complete_view.[Product Category],complete_view.[Sub Category]
	HAVING complete_view.Gender = 'Male'
)
SELECT	Female_tbl.[Product Category],
		Female_tbl.[Sub Category],
		Female_tbl.Total_SaleAmount_Female,
		Male_tbl.Total_SaleAmount_Male,
		Female_tbl.Total_SaleAmount_Female/Male_tbl.Total_SaleAmount_Male AS Ratio_Female_VS_Male
FROM Female_tbl INNER JOIN Male_tbl ON Female_tbl.[Sub Category] =Male_tbl.[Sub Category]
ORDER BY Female_tbl.[Product Category],Female_tbl.[Sub Category]
-- Results indicating that Gender is not a significant factor in selection of products SubCategories


/****************** Top Products 5 Products Among Male and Female ******************/

-- Query written in Two parts(one for male and other for female) as two CTEs and Joined. Created view on the O/P joined CTEs.
-- Created this view to fecilitate filter over Product categories
DROP VIEW MaleFemale_TOP_Products_view
CREATE VIEW MaleFemale_TOP_Products_view AS 

	WITH Female_Top_prod_cte AS -- CTE1 for filtering female data
	(
		SELECT tb2.[Product Category] AS ProductCategory_Female,tb2.[Product Name] AS ProductName_Female,tb2.Total_SaleAmount_Female
		FROM
			(
				SELECT *,
						RANK() OVER (PARTITION BY tb1.[Product Category] ORDER BY tb1.Total_SaleAmount_Female DESC) AS Rank_Across_Product_Female
				FROM 
					(
						SELECT complete_view.Gender,complete_view.[Product Category],complete_view.[Product Name],SUM(complete_view.SalesAmount) AS Total_SaleAmount_Female
						FROM complete_view
						GROUP BY complete_view.Gender,complete_view.[Product Category],complete_view.[Product Name]
						HAVING complete_view.Gender = 'Female'
		
					) AS tb1
			) AS tb2
		WHERE Rank_Across_Product_Female IN (1,2,3,4,5)
	),
	Male_Top_prod_cte AS -- cte2 for filtering male data
	(
		SELECT tb2.[Product Category] AS ProductCategory_male,tb2.[Product Name] AS ProductName_male,tb2.Total_SaleAmount_Male
		FROM
			(
				SELECT *,
						RANK() OVER (PARTITION BY tb1.[Product Category] ORDER BY tb1.Total_SaleAmount_Male DESC) AS Rank_Across_Product_Male
				FROM 
					(
						SELECT complete_view.Gender,complete_view.[Product Category],complete_view.[Product Name],SUM(complete_view.SalesAmount) AS Total_SaleAmount_Male
						FROM complete_view
						GROUP BY complete_view.Gender,complete_view.[Product Category],complete_view.[Product Name]
						HAVING complete_view.Gender = 'Male'
		
					) AS tb1
			) AS tb2
		WHERE Rank_Across_Product_Male IN (1,2,3,4,5)
	)
	SELECT * -- Joining of male and female data on Product Name using ctes'
	FROM Female_Top_prod_cte FULL JOIN Male_Top_prod_cte ON Female_Top_prod_cte.ProductName_Female = Male_Top_prod_cte.ProductName_male

-- Filtering of Product category 'Accessories' 
Select * FROM MaleFemale_TOP_Products_view
WHERE ProductCategory_Female = 'Accessories' OR ProductCategory_male = 'Accessories'
-- Filtering of Product category 'Bikes' 
Select * FROM MaleFemale_TOP_Products_view
WHERE ProductCategory_Female = 'Bikes' OR ProductCategory_male = 'Bikes'
-- Filtering of Product category 'Clothing'
Select * FROM MaleFemale_TOP_Products_view
WHERE ProductCategory_Female = 'Clothing' OR ProductCategory_male = 'Clothing'
--O/P
-- After Comparing the O/P of the above 3 queries its clear that there is almost no difference in choices made Female and Male cutomers in Accessories and bikes product categories
-- There is a claar difference in choice of clothing between male and female

























--Doubt
-- Why cat we write CTE over the complete qery 

	WITH Female_Top_prod_cte AS -- CTE1 for filtering female data
	(
		SELECT tb2.[Product Category] AS ProductCategory_Female,tb2.[Product Name] AS ProductName_Female,tb2.Total_SaleAmount_Female
		FROM
			(
				SELECT *,
						RANK() OVER (PARTITION BY tb1.[Product Category] ORDER BY tb1.Total_SaleAmount_Female) AS Rank_Across_Product_Female
				FROM 
					(
						SELECT complete_view.Gender,complete_view.[Product Category],complete_view.[Product Name],SUM(complete_view.SalesAmount) AS Total_SaleAmount_Female
						FROM complete_view
						GROUP BY complete_view.Gender,complete_view.[Product Category],complete_view.[Product Name]
						HAVING complete_view.Gender = 'Female'
		
					) AS tb1
			) AS tb2
		WHERE Rank_Across_Product_Female IN (1,2,3,4,5)
	),
	Male_Top_prod_cte AS -- cte2 for filtering male data
	(
		SELECT tb4.[Product Category] AS ProductCategory_male,tb4.[Product Name] AS ProductName_male,tb4.Total_SaleAmount_Male
		FROM
			(
				SELECT *,
						RANK() OVER (PARTITION BY tb3.[Product Category] ORDER BY tb3.Total_SaleAmount_Male) AS Rank_Across_Product_Male
				FROM 
					(
						SELECT complete_view.Gender,complete_view.[Product Category],complete_view.[Product Name],SUM(complete_view.SalesAmount) AS Total_SaleAmount_Male
						FROM complete_view
						GROUP BY complete_view.Gender,complete_view.[Product Category],complete_view.[Product Name]
						HAVING complete_view.Gender = 'Male'
		
					) AS tb3
			) AS tb4
		WHERE Rank_Across_Product_Male IN (1,2,3,4,5)
	)
	SELECT * -- Joining of male and female data on Product Name using ctes'
	FROM Female_Top_prod_cte FULL JOIN Male_Top_prod_cte ON Female_Top_prod_cte.ProductName_Female = Male_Top_prod_cte.ProductName_male





	
