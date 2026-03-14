--*************************************************************************--
-- Title: Assignment07
-- Author: VNguyen
-- Desc: This file demonstrates how to use Functions
-- Change Log: When,Who,What
-- 2026-03-08,VNguyen,Created File
--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment07DB_VNguyen')
	 Begin 
	  Alter Database [Assignment07DB_VNguyen] set Single_user With Rollback Immediate;
	  Drop Database Assignment07DB_VNguyen;
	 End
	Create Database Assignment07DB_VNguyen;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment07DB_VNguyen;

-- Create Tables (Module 01)-- 
Create Table Categories
([CategoryID] [int] IDENTITY(1,1) NOT NULL 
,[CategoryName] [nvarchar](100) NOT NULL
);
go

Create Table Products
([ProductID] [int] IDENTITY(1,1) NOT NULL 
,[ProductName] [nvarchar](100) NOT NULL 
,[CategoryID] [int] NULL  
,[UnitPrice] [money] NOT NULL
);
go

Create Table Employees -- New Table
([EmployeeID] [int] IDENTITY(1,1) NOT NULL 
,[EmployeeFirstName] [nvarchar](100) NOT NULL
,[EmployeeLastName] [nvarchar](100) NOT NULL 
,[ManagerID] [int] NULL  
);
go

Create Table Inventories
([InventoryID] [int] IDENTITY(1,1) NOT NULL
,[InventoryDate] [Date] NOT NULL
,[EmployeeID] [int] NOT NULL
,[ProductID] [int] NOT NULL
,[ReorderLevel] int NOT NULL -- New Column 
,[Count] [int] NOT NULL
);
go

-- Add Constraints (Module 02) -- 
Begin  -- Categories
	Alter Table Categories 
	 Add Constraint pkCategories 
	  Primary Key (CategoryId);

	Alter Table Categories 
	 Add Constraint ukCategories 
	  Unique (CategoryName);
End
go 

Begin -- Products
	Alter Table Products 
	 Add Constraint pkProducts 
	  Primary Key (ProductId);

	Alter Table Products 
	 Add Constraint ukProducts 
	  Unique (ProductName);

	Alter Table Products 
	 Add Constraint fkProductsToCategories 
	  Foreign Key (CategoryId) References Categories(CategoryId);

	Alter Table Products 
	 Add Constraint ckProductUnitPriceZeroOrHigher 
	  Check (UnitPrice >= 0);
End
go

Begin -- Employees
	Alter Table Employees
	 Add Constraint pkEmployees 
	  Primary Key (EmployeeId);

	Alter Table Employees 
	 Add Constraint fkEmployeesToEmployeesManager 
	  Foreign Key (ManagerId) References Employees(EmployeeId);
End
go

Begin -- Inventories
	Alter Table Inventories 
	 Add Constraint pkInventories 
	  Primary Key (InventoryId);

	Alter Table Inventories
	 Add Constraint dfInventoryDate
	  Default GetDate() For InventoryDate;

	Alter Table Inventories
	 Add Constraint fkInventoriesToProducts
	  Foreign Key (ProductId) References Products(ProductId);

	Alter Table Inventories 
	 Add Constraint ckInventoryCountZeroOrHigher 
	  Check ([Count] >= 0);

	Alter Table Inventories
	 Add Constraint fkInventoriesToEmployees
	  Foreign Key (EmployeeId) References Employees(EmployeeId);
End 
go

-- Adding Data (Module 04) -- 
Insert Into Categories 
(CategoryName)
Select CategoryName 
 From Northwind.dbo.Categories
 Order By CategoryID;
go

Insert Into Products
(ProductName, CategoryID, UnitPrice)
Select ProductName,CategoryID, UnitPrice 
 From Northwind.dbo.Products
  Order By ProductID;
go

Insert Into Employees
(EmployeeFirstName, EmployeeLastName, ManagerID)
Select E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID) 
 From Northwind.dbo.Employees as E
  Order By E.EmployeeID;
go

Insert Into Inventories
(InventoryDate, EmployeeID, ProductID, [Count], [ReorderLevel]) -- New column added this week
Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, UnitsInStock, ReorderLevel
From Northwind.dbo.Products
UNIOn
Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, UnitsInStock + 10, ReorderLevel -- Using this is to create a made up value
From Northwind.dbo.Products
UNIOn
Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, abs(UnitsInStock - 10), ReorderLevel -- Using this is to create a made up value
From Northwind.dbo.Products
Order By 1, 2
go


-- Adding Views (Module 06) -- 
Create View vCategories With SchemaBinding
 AS
  Select CategoryID, CategoryName From dbo.Categories;
go
Create View vProducts With SchemaBinding
 AS
  Select ProductID, ProductName, CategoryID, UnitPrice From dbo.Products;
go
Create View vEmployees With SchemaBinding
 AS
  Select EmployeeID, EmployeeFirstName, EmployeeLastName, ManagerID From dbo.Employees;
go
Create View vInventories With SchemaBinding 
 AS
  Select InventoryID, InventoryDate, EmployeeID, ProductID, ReorderLevel, [Count] From dbo.Inventories;
go

-- Show the Current data in the Categories, Products, and Inventories Tables
Select * From vCategories;
go
Select * From vProducts;
go
Select * From vEmployees;
go
Select * From vInventories;
go

/********************************* Questions and Answers *********************************/
Print
'NOTES------------------------------------------------------------------------------------ 
 1) You must use the BASIC views for each table.
 2) To make sure the Dates are sorted correctly, you can use Functions in the Order By clause!
------------------------------------------------------------------------------------------'
-- Question 1 (5% of pts):
-- Show a list of Product names and the price of each product.
-- Use a function to format the price as US dollars.
-- Order the result by the product name.

--	select P.ProductName, P.UnitPrice						-- start off with the base of what we learned last assigment
--		from vProducts as P									-- no create view as it is not specified
--		order by P.ProductName

select P.ProductName, 
	Format(P.UnitPrice, 'C', 'en-US') as UnitPrice			-- refered to Mod07 Notes page 6 title The Format Function
	from vProducts as P										-- I tried to do 'as P.UnitPrice' which gave me syntax error on the period so I assume the P. is unnecessary
	order by P.ProductName
go

-- Question 2 (10% of pts): 
-- Show a list of Category and Product names, and the price of each product.
-- Use a function to format the price as US dollars.
-- Order the result by the Category and Product.

select 
	C.CategoryName, 
	P.ProductName, 
	Format(P.UnitPrice, 'C', 'en-US') as UnitPrice
	from vCategories as C 
	join vProducts as P 
	on C.CategoryID = P.CategoryID
	order by C.CategoryName, P.ProductName
go

-- Question 3 (10% of pts): 
-- Use functions to show a list of Product names, each Inventory Date, and the Inventory Count.
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.

select 
	P.ProductName, 
	DateName(Month,I.InventoryDate) + ', ' + DateName(Year,I.InventoryDate) as InventoryDate,		-- refered to Mod07 Notes page 10 title Date/Time Functions
	I.[Count] 
	from vProducts as P 
	join vInventories as I 
	on P.ProductID = I.ProductID
	order by P.ProductName, I.InventoryDate
go

-- Question 4 (10% of pts): 
-- CREATE A VIEW called vProductInventories. 
-- Shows a list of Product names, each Inventory Date, and the Inventory Count. 
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.

create view vProductInventories																		-- identical to last question plus this line
	as select top 1000																				-- select top to circumvent order by issue
	P.ProductName, 
	DateName(Month,I.InventoryDate) + ', ' + DateName(Year,I.InventoryDate) as InventoryDate,		-- refered to Mod07 Notes page 10 title Date/Time Functions
	I.[Count] as InventoryCount
	from vProducts as P 
	join vInventories as I 
	on P.ProductID = I.ProductID
	order by P.ProductName, I.InventoryDate
go

select * From vProductInventories
go

-- Question 5 (10% of pts): 
-- CREATE A VIEW called vCategoryInventories. 
-- Shows a list of Category names, Inventory Dates, and a TOTAL Inventory Count BY CATEGORY
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.

create view vCategoryInventories
	as select top 1000
	C.CategoryName, 
	DateName(Month,I.InventoryDate) + ', ' + DateName(Year,I.InventoryDate) as InventoryDate,
	Sum(I.[Count]) as InventoryCountByCategory															-- refered to Mod07 Notes page 3 Grouping for Sub-Totals
	from vCategories as C
	join vProducts as P
	on C.CategoryID = P.CategoryID
	join vInventories as I
	on P.ProductID = I.ProductID
	group by C.CategoryName, I.InventoryDate 
	order by C.CategoryName, I.InventoryDate
go

select * from vCategoryInventories
go

-- Question 6 (10% of pts): 
-- CREATE ANOTHER VIEW called vProductInventoriesWithPreviousMonthCounts. 
-- Show a list of Product names, Inventory Dates, Inventory Count, AND the Previous Month Count.
-- Use functions to set any January NULL counts to zero. 
-- Order the results by the Product and Date. 
-- This new view must use your vProductInventories view.

create view vProductInventoriesWithPreviousMonthCounts
	as select top 1000
	ProductName,
	InventoryDate,
	InventoryCount,
	IIF (InventoryDate = ('January, 2017'), 0,													-- I had to figure out this IIF statement because I ran into an error doing question 7 where my aniseed syrup previous month count was not matching the picture in Assigment07.pdf
	Lag(InventoryCount) over (order by ProductName, Month(InventoryDate)))						-- refered to Mod07 Notes page 14 Lag and Lead, originally I had an IsNull statement here, figured out why you said not to use it in Mod07 Notes
	as PreviousMonthCount																		-- IsNull didn't do what I needed and when I added my IIF statement, the IsNull seemed to not do anything so I took it out
	from vProductInventories
	order by ProductName, Month(InventoryDate), InventoryCount
go

select * from vProductInventoriesWithPreviousMonthCounts
go

-- Question 7 (15% of pts): 
-- CREATE a VIEW called vProductInventoriesWithPreviousMonthCountsWithKPIs.
-- Show columns for the Product names, Inventory Dates, Inventory Count, Previous Month Count. 
-- The Previous Month Count is a KPI. The result can show only KPIs with a value of either 1, 0, or -1. 
-- Display months with increased counts as 1, same counts as 0, and decreased counts as -1. 
-- Varify that the results are ordered by the Product and Date.

create view vProductInventoriesWithPreviousMonthCountsWithKPIs
	as select top 1000
	ProductName,
	InventoryDate,
	InventoryCount,
	PreviousMonthCount,
	CountVsPreviousCountKPI=															-- I was doing as (name) at the end but it did not work for this one so I copied the formatting shown in notes
	case
	when InventoryCount > PreviousMonthCount then 1
	when InventoryCount = PreviousMonthCount then 0
	when InventoryCount < PreviousMonthCount then -1
	end
	from vProductInventoriesWithPreviousMonthCounts
	order by ProductName, Month(InventoryDate)
go

select * from vProductInventoriesWithPreviousMonthCountsWithKPIs
go

-- Question 8 (25% of pts): 
-- CREATE a User Defined Function (UDF) called fProductInventoriesWithPreviousMonthCountsWithKPIs.
-- Show columns for the Product names, Inventory Dates, Inventory Count, the Previous Month Count. 
-- The Previous Month Count is a KPI. The result can show only KPIs with a value of either 1, 0, or -1. 
-- Display months with increased counts as 1, same counts as 0, and decreased counts as -1. 
-- The function must use the ProductInventoriesWithPreviousMonthCountsWithKPIs view.
-- Varify that the results are ordered by the Product and Date.

--  CREATE FUNCTION (@storeid INT)																	-- i went to learn.microsoft.com to learn how to use create function
--	RETURNS TABLE																					-- this is the code they had as an example with all the innards deleted
--	AS																								-- i will use it as a skeleton skipping the parts that I don't need like the where statement
--	RETURN
--	(
--  SELECT 
--  FROM 
--  WHERE
--  GROUP BY
--	);

--	create function fProductInventoriesWithPreviousMonthCountsWithKPIs (@storeid INT)
--		returns table as return																		-- scrunched first few lines together
--		select top 1000																				-- select top because it gives an error when I try to order by
--		ProductName,																				-- add relevant collumn names
--		InventoryDate,
--		InventoryCount,
--		PreviousMonthCount,
--		CountVsPreviousCountKPI
--		from vProductInventoriesWithPreviousMonthCountsWithKPIs										-- no join or as statements because we are not joining anything
--		where CountVsPreviousCountKPI = @storeid													-- kept name the same for now to not get confused
--		group by ProductName, InventoryDate, InventoryCount,PreviousMonthCount						-- I'm still not fully understanding how this group by statement works, sometimes not using it gives me an error, other times using it messes everything up 																							

create function fProductInventoriesWithPreviousMonthCountsWithKPIs (@KPI INT)						-- also rename up here
	returns table as return
	select top 1000
	ProductName,
	InventoryDate,
	InventoryCount,
	PreviousMonthCount,
	CountVsPreviousCountKPI
	from vProductInventoriesWithPreviousMonthCountsWithKPIs
	where CountVsPreviousCountKPI = @KPI																	-- rename the value name
	group by ProductName, InventoryDate, InventoryCount, PreviousMonthCount, CountVsPreviousCountKPI
	order by ProductName, Month(InventoryDate)																-- add group by clause	-- at this point the code lines up with the picture in Assigment 07 so hopefully this code is good
go


select * from fProductInventoriesWithPreviousMonthCountsWithKPIs(1);
select * from fProductInventoriesWithPreviousMonthCountsWithKPIs(0);
select * from fProductInventoriesWithPreviousMonthCountsWithKPIs(-1);

go

/***************************************************************************************/