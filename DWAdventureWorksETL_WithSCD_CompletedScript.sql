--*************************************************************************--
-- Title: Assignment02: Modify Data Warehouse with SCD columns for Incremental ETL loading

-- Instructions: 
-- (STEP 1) Restore the AdventureWorks_Basics database by running the provided code.
-- (STEP 2) Create a new Data Warehouse called DWAdventureWorks_Basics based on the AdventureWorks_Basics DB.
--          The DW should have three dimension tables (for Customers, Products, and Dates) and one fact table.
-- (STEP 3) Fill the DW by creating an ETL Script
--**************************************************************************--

USE [DWAdventureWorks_BasicsWithSCD];
Go
SET NoCount ON;
Go
/*===========================================  DimProducts  =====================================================*/

DROP VIEW If Exists dbo.vETLDimProducts
GO

Create VIEW vETLDimProducts
AS
	 SELECT
	  [ProductID] = Products.ProductID
	 ,[ProductName] = CAST([Products].[Name] as nVarchar(50))
	 ,[StandardListPrice] = Cast([Products].[ListPrice] as Decimal(18,4))
	 ,[ProductSubCategoryID] = isNull(ProductSubcategory.ProductSubcategoryID,-1)
	 ,[ProductSubCategoryName] = Cast(isNull([ProductSubcategory].[Name],'NA') as nvarchar(50))
	 ,[ProductCategoryID] = isNull([ProductSubCategory].[ProductCategoryID],-1)
	 ,[ProductCategoryName] = Cast(isNull([ProductCategory].[Name],'NA') as nvarchar(50))
	 ,[StartDate] = Cast('2005-07-01' as date)
	 ,[EndDate] = NULL
	 ,[IsCurrent] = 1

	FROM [AdventureWorks_Basics].dbo.Products
	LEFT JOIN [AdventureWorks_Basics].dbo.ProductSubcategory
	ON Products.ProductSubcategoryID = ProductSubcategory.ProductSubcategoryID
	LEFT JOIN [AdventureWorks_Basics].dbo.ProductCategory
	ON ProductSubcategory.ProductCategoryID = ProductCategory.ProductCategoryID;
	Go
/*Testing Code
Select * From vETLDimProducts;
*/

DROP Procedure If Exists dbo.pETLInsDimProducts;
Go
CREATE PROCEDURE pETLInsDimProducts
As
 Begin
	Declare @RC int = 0;
	Begin Try
		With NewProducts 
		As
		(
			Select ProductID From vETLDimProducts
			Except
			Select ProductID From DimProducts
		)
		Insert Into DimProducts 
		   ( [ProductID]
		   , [ProductName]
		   , [StandardListPrice]
		   , [ProductSubCategoryID]
		   , [ProductSubCategoryName]
		   , [ProductCategoryID]
		   , [ProductCategoryName]
		   , [StartDate]
		   , [EndDate]
		   , [IsCurrent])
			Select 
		     [ProductID]
		   , [ProductName]
		   , [StandardListPrice]
		   , [ProductSubCategoryID]
		   , [ProductSubCategoryName]
		   , [ProductCategoryID]
		   , [ProductCategoryName]
		   , Cast(GetDate() as date)
		   , NULL
		   , 1
		   From vETLDimProducts
		   Where ProductID in (Select ProductID from NewProducts);
  Set @RC = +1
	 END Try
	 Begin Catch
	  Print Error_Message()
	  Set @RC = -1
	 End Catch
	 Return @RC;
	END
Go
/* Testing data
 Declare @Status int;
 EXEC @Status = pETLInsDimProducts
 Print @Status;
 Select * From DimProducts;
*/

DROP Procedure If Exists dbo.pETLUpdDimProducts;
Go

CREATE PROCEDURE pETLUpdDimProducts
As
 Begin
	Declare @RC int = 0;
	Begin Try
	With UpdatedProducts 
		As
		(
			Select [ProductID], [ProductName], [StandardListPrice], [ProductSubCategoryID], [ProductSubCategoryName], [ProductCategoryID], [ProductCategoryName]
			From vETLDimProducts
			Except
			Select [ProductID], [ProductName], [StandardListPrice], [ProductSubCategoryID], [ProductSubCategoryName], [ProductCategoryID], [ProductCategoryName]
			From DimProducts
			Where isCurrent = 1 
		)
		Update DimProducts
			Set EndDate = Cast(GetDate() as Date)
			   ,IsCurrent = 0
			Where ProductId In (Select ProductId From UpdatedProducts );
	With InsUpdatedProducts 
		As
		(
			Select [ProductID], [ProductName], [StandardListPrice], [ProductSubCategoryID], [ProductSubCategoryName], [ProductCategoryID], [ProductCategoryName]
			From vETLDimProducts
			Except
			Select [ProductID], [ProductName], [StandardListPrice], [ProductSubCategoryID], [ProductSubCategoryName], [ProductCategoryID], [ProductCategoryName]
			From DimProducts
		)
		Insert Into DimProducts 
		   ( [ProductID]
		   , [ProductName]
		   , [StandardListPrice]
		   , [ProductSubCategoryID]
		   , [ProductSubCategoryName]
		   , [ProductCategoryID]
		   , [ProductCategoryName]
		   , [StartDate]
		   , [EndDate]
		   , [IsCurrent])
			Select 
		     [ProductID]
		   , [ProductName]
		   , [StandardListPrice]
		   , [ProductSubCategoryID]
		   , [ProductSubCategoryName]
		   , [ProductCategoryID]
		   , [ProductCategoryName]
		   , Cast(GetDate() as date)
		   , NULL
		   , 1
		   From vETLDimProducts
		   Where ProductId In (Select ProductId From InsUpdatedProducts );
 Set @RC = +1
	 END Try
	 Begin Catch
	  Print Error_Message()
	  Set @RC = -1
	 End Catch
	 Return @RC;
	END
Go
/* Testing data
 Declare @Status int;
 EXEC @Status = pETLUpdDimProducts
 Print @Status;
 Select * From DimProducts;
*/

DROP Procedure If Exists dbo.pETLDelDimProducts;
Go

CREATE PROCEDURE pETLDelDimProducts
As
 Begin
	Declare @RC int = 0;
	Begin Try
	With DelProducts 
		As
		(
			Select [ProductID], [ProductName], [StandardListPrice], [ProductSubCategoryID], [ProductSubCategoryName], [ProductCategoryID], [ProductCategoryName]
			From DimProducts
			Where IsCurrent = 1
			Except
			Select [ProductID], [ProductName], [StandardListPrice], [ProductSubCategoryID], [ProductSubCategoryName], [ProductCategoryID], [ProductCategoryName]
			From vETLDimProducts
		)
			Update DimProducts
			Set EndDate = Cast(GetDate() as Date)
			   ,IsCurrent = 0
			Where ProductId In (Select ProductId From DelProducts );
		Set @RC = +1
	 END Try
	 Begin Catch
	  Print Error_Message()
	  Set @RC = -1
	 End Catch
	 Return @RC;
	END
Go
/* Testing data
 Declare @Status int;
 EXEC @Status = pETLDelDimProducts
 Print @Status;
 Select * From DimProducts;
*/

DROP Procedure If Exists dbo.pETLSyncDimProducts;
Go

CREATE PROCEDURE pETLSyncDimProducts
As
 Begin
	Declare @RC int = 0;
	Begin Try
		Execute pETLInsDimProducts;
		Execute pETLUpdDimProducts;
		Execute pETLDelDimProducts;
	Set @RC = +1
	END Try
	 Begin Catch
	  Print Error_Message()
	  Set @RC = -1
	 End Catch
	 Return @RC;
	END
Go
/* Testing data
 Declare @Status int;
 EXEC @Status = pETLSyncDimProducts
 Print @Status;
 Select * From DimProducts;
*/

/*===========================================  DimCustomers  =====================================================*/

DROP VIEW If Exists dbo.vETLDimCustomers
Go

Create VIEW vETLDimCustomers 
AS
	SELECT
	 [CustomerID] = [Customer].[CustomerID]
	,[CustomerFullName] = Cast(CONCAT(Customer.FirstName,' ',Customer.LastName) as nvarchar(100))
	,[CustomerCityName] = Cast(Customer.City as nvarchar(50))
	,[CustomerStateProvinceName] = Cast(Customer.StateProvinceName as nvarchar(50))
	,[CustomerCountryRegionCode] = Cast(Customer.CountryRegionCode as nvarchar(50))
	,[CustomerCountryRegionName] = Cast(Customer.CountryRegionName as nvarchar(50))
	,[StartDate] = Cast('2005-07-01' as date)
    ,[EndDate] = NULL
	,[IsCurrent] = 1
	
	FROM [AdventureWorks_Basics].[dbo].[Customer];
	Go
/*Testing Code
Select * From vETLDimCustomers;
*/

DROP Procedure If Exists dbo.pETLInsDimCustomers;
Go
CREATE PROCEDURE pETLInsDimCustomers
As
 Begin
	Declare @RC int = 0;
	Begin Try
		With NewCustomers 
		As
		(
			Select CustomerID From vETLDimCustomers
			Except
			Select CustomerID From DimCustomers
		)
		Insert Into DimCustomers 
		   ( [CustomerId]
		   , [CustomerFullName]
		   , [CustomerCityName]
		   , [CustomerStateProvinceName]
		   , [CustomerCountryRegionCode]
		   , [CustomerCountryRegionName]
		   , [StartDate]
		   , [EndDate]
		   , [IsCurrent])
			Select 
		     [CustomerId]
		   , [CustomerFullName]
		   , [CustomerCityName]
		   , [CustomerStateProvinceName]
		   , [CustomerCountryRegionCode]
		   , [CustomerCountryRegionName]
		   , Cast(GetDate() as date)
		   , NULL
		   , 1
		   From vETLDimCustomers
		   Where CustomerID in (Select CustomerID from NewCustomers);
  Set @RC = +1
	 END Try
	 Begin Catch
	  Print Error_Message()
	  Set @RC = -1
	 End Catch
	 Return @RC;
	END
Go
/* Testing data
 Declare @Status int;
 EXEC @Status = pETLInsDimCustomers
 Print @Status;
 Select * From DimCustomers;
*/

DROP Procedure If Exists dbo.pETLUpdDimCustomers;
Go

CREATE PROCEDURE pETLUpdDimCustomers
As
 Begin
	Declare @RC int = 0;
	Begin Try
	With UpdatedCustomers 
		As
		(
			Select [CustomerId], [CustomerFullName], [CustomerCityName], [CustomerStateProvinceName], [CustomerCountryRegionCode], [CustomerCountryRegionName]
			From vETLDimCustomers
			Except
			Select [CustomerId], [CustomerFullName], [CustomerCityName], [CustomerStateProvinceName], [CustomerCountryRegionCode], [CustomerCountryRegionName]
			From DimCustomers
			Where isCurrent = 1 
		)
		Update DimCustomers
			Set EndDate = Cast(GetDate() as Date)
			   ,IsCurrent = 0
			Where CustomerId In (Select CustomerId From UpdatedCustomers );
	With InsUpdatedCustomers 
		As
		(
			Select [CustomerId], [CustomerFullName], [CustomerCityName], [CustomerStateProvinceName], [CustomerCountryRegionCode], [CustomerCountryRegionName]
			From vETLDimCustomers
			Except
			Select [CustomerId], [CustomerFullName], [CustomerCityName], [CustomerStateProvinceName], [CustomerCountryRegionCode], [CustomerCountryRegionName]
			From DimCustomers
		)
			Insert Into DimCustomers 
		   ( [CustomerId]
		   , [CustomerFullName]
		   , [CustomerCityName]
		   , [CustomerStateProvinceName]
		   , [CustomerCountryRegionCode]
		   , [CustomerCountryRegionName]
		   , [StartDate]
		   , [EndDate]
		   , [IsCurrent])
			Select 
		     [CustomerId]
		   , [CustomerFullName]
		   , [CustomerCityName]
		   , [CustomerStateProvinceName]
		   , [CustomerCountryRegionCode]
		   , [CustomerCountryRegionName]
		   , Cast(GetDate() as date)
		   , NULL
		   , 1
		   From vETLDimCustomers
		   Where CustomerId In (Select CustomerId From InsUpdatedCustomers );
 Set @RC = +1
	 END Try
	 Begin Catch
	  Print Error_Message()
	  Set @RC = -1
	 End Catch
	 Return @RC;
	END
Go
/* Testing data
 Declare @Status int;
 EXEC @Status = pETLUpdDimCustomers
 Print @Status;
 Select * From DimCustomers;
*/

DROP Procedure If Exists dbo.pETLDelDimCustomers;
Go

CREATE PROCEDURE pETLDelDimCustomers
As
 Begin
	Declare @RC int = 0;
	Begin Try
	With DelCustomers
		As
		(
			Select [CustomerId], [CustomerFullName], [CustomerCityName], [CustomerStateProvinceName], [CustomerCountryRegionCode], [CustomerCountryRegionName]
			From DimCustomers
			Where IsCurrent = 1
			Except
			Select [CustomerId], [CustomerFullName], [CustomerCityName], [CustomerStateProvinceName], [CustomerCountryRegionCode], [CustomerCountryRegionName]
			From vETLDimCustomers
		)
			Update DimCustomers
			Set EndDate = Cast(GetDate() as Date)
			   ,IsCurrent = 0
			Where CustomerId In (Select CustomerId From DelCustomers );
		Set @RC = +1
	 END Try
	 Begin Catch
	  Print Error_Message()
	  Set @RC = -1
	 End Catch
	 Return @RC;
	END
Go
/* Testing data
 Declare @Status int;
 EXEC @Status = pETLDelDimCustomers
 Print @Status;
 Select * From DimCustomers;
*/

DROP Procedure If Exists dbo.pETLSyncDimCustomers;
Go

CREATE PROCEDURE pETLSyncDimCustomers
As
 Begin
	Declare @RC int = 0;
	Begin Try
		Execute pETLInsDimCustomers;
		Execute pETLUpdDimCustomers;
		Execute pETLDelDimCustomers;
	Set @RC = +1
	END Try
	 Begin Catch
	  Print Error_Message()
	  Set @RC = -1
	 End Catch
	 Return @RC;
	END
Go
/* Testing data
 Declare @Status int;
 EXEC @Status = pETLSyncDimCustomers
 Print @Status;
 Select * From DimCustomers;
*/

/*===========================================  DimDates  =====================================================*/
DROP PROCEDURE If Exists dbo.pETLFillDimDates
Go

Create PROCEDURE pETLFillDimDates 
AS
	Begin
	  Declare @RC int = 0;
	  Begin Try
		-- ETL Processing Code --
			Alter Table [DWAdventureWorks_BasicsWithSCD].dbo.FactSalesOrders -- Dropping FK
			Drop Constraint [FK_FactSalesOrders_DimDates]; 
		Delete From DimDates; -- Clears table data with the need for dropping FKs
		-- Create variables to hold the start and end date
		Declare @StartDate datetime = '01/01/2005'
		Declare @EndDate datetime = '12/31/2020' 

		-- Use a while loop to add dates to the table
		Declare @DateInProcess datetime
		Set @DateInProcess = @StartDate

		While @DateInProcess <= @EndDate
		 Begin
		 -- Add a row into the date dimension table for this date
		 Insert Into DimDates 
		 ( [DateKey], [FullDate], [FullDateName], [MonthID], [MonthName], [YearID], [YearName] )
		 Values ( 
			Cast(Convert(nvarchar(50), @DateInProcess , 112) as int) -- [DateKey]
		  , @DateInProcess -- [FullDate]
		  , DateName( weekday, @DateInProcess ) + ', ' + Convert(nvarchar(50), @DateInProcess , 110) -- [FullDateName]  
		  , Left(Cast(Convert(nvarchar(50), @DateInProcess , 112) as int), 6) -- [MonthID]   
		  , DateName( MONTH, @DateInProcess ) + ', ' + Cast( Year(@DateInProcess ) as nVarchar(50) ) -- [MonthName]
		  , Year( @DateInProcess ) -- [YearKey]
		  , Cast( Year(@DateInProcess ) as nVarchar(50) ) -- [YearName] 
		  )  
		 -- Add a day and loop again
		 Set @DateInProcess = DateAdd(d, 1, @DateInProcess)
		End
		ALTER TABLE DWAdventureWorks_BasicsWithSCD.dbo.FactSalesOrders -- Add FK back
		  ADD CONSTRAINT FK_FactSalesOrders_DimDates 
		  FOREIGN KEY (OrderDateKey) REFERENCES DimDates(DateKey)
	Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
Go

/* Testing Code:
 Declare @Status int;
 Exec @Status = pETLFillDimDates;
 Print @Status;
  Select * From DimDates;
*/

/*===========================================  FactSalesOrders  =====================================================*/
DROP VIEW If Exists dbo.vETLFactSalesOrders
Go

Create VIEW vETLFactSalesOrders
AS
	SELECT
	 [SalesOrderID] = SalesOrderHeader.SalesOrderID
	,[SalesOrderDetailID] = SalesOrderDetail.SalesOrderDetailID
	,[OrderDate] = Cast(DimDates.FullDate as date)
	,[OrderDateKey] = DimDates.DateKey
	,[CustomerID] = DimCustomers.CustomerId
	,[CustomerKey] = DimCustomers.CustomerKey
	,[ProductID] = DimProducts.ProductID
	,[ProductKey] = DimProducts.ProductKey
	,[OrderQty] = SalesOrderDetail.OrderQty
	,[ActualUnitPrice] = SalesOrderDetail.UnitPrice

	FROM   [AdventureWorks_Basics].dbo.SalesOrderHeader
LEFT JOIN [AdventureWorks_Basics].dbo.SalesOrderDetail 
	ON SalesOrderHeader.SalesOrderID = SalesOrderDetail.SalesOrderID 
LEFT JOIN  [DWAdventureWorks_BasicsWithSCD].dbo.DimCustomers
	ON SalesOrderHeader.CustomerID = DimCustomers.CustomerID 
	AND DimCustomers.IsCurrent = 1
LEFT JOIN [DWAdventureWorks_BasicsWithSCD].dbo.DimProducts
	ON SalesOrderDetail.ProductID = DimProducts.ProductID
	AND DimProducts.IsCurrent = 1
LEFT JOIN [DWAdventureWorks_BasicsWithSCD].dbo.DimDates
	On DimDates.DateKey = isNull(Convert(nvarchar(50), SalesOrderHeader.OrderDate, 112), '-1')
Go
/*Testing Code
Select * From vETLFactSalesOrders;
*/

DROP PROCEDURE If Exists dbo.pETLSyncFactSalesOrders
GO

Create PROCEDURE pETLSyncFactSalesOrders
As
 Begin
	Declare @RC int = 0;
	Begin Try
		Merge Into FactSalesOrders as TargetTable
				Using vETLFactSalesOrders as SourceTable
					ON TargetTable.SalesOrderDetailID = SourceTable.SalesOrderDetailID
					When Not Matched 
						Then -- The ID in the Source is not found the the Target
							INSERT
							(  SalesOrderID
							  ,SalesOrderDetailID
							  ,OrderDateKey
							  ,CustomerKey
							  ,ProductKey
							  ,OrderQty
							  ,ActualUnitPrice )
							VALUES ( SourceTable.SalesOrderID
							        ,SourceTable.SalesOrderDetailID
								    ,SourceTable.OrderDateKey
								    ,SourceTable.CustomerKey
									,SourceTable.ProductKey
									,SourceTable.OrderQty
									,SourceTable.ActualUnitPrice )
					When Matched -- When the IDs match for the row currently being looked 
					AND ( SourceTable.SalesOrderID <> TargetTable.SalesOrderID -- but the SalesOrderID 
						OR SourceTable.OrderDateKey <> TargetTable.OrderDateKey  -- or OrderDate
						OR SourceTable.CustomerKey <> TargetTable.CustomerKey -- or CustomerKey
						OR SourceTable.ProductKey <> TargetTable.ProductKey -- or ProductKey
						OR SourceTable.OrderQty <> TargetTable.OrderQty -- or OrderQty
						OR SourceTable.ActualUnitPrice <> TargetTable.ActualUnitPrice ) -- or ActualUnitPrice do not match
						Then 
							UPDATE -- Update the differences for the matched IDs
							SET TargetTable.SalesOrderID = SourceTable.SalesOrderID
							  , TargetTable.OrderDateKey = SourceTable.OrderDateKey 
							  , TargetTable.CustomerKey = SourceTable.CustomerKey
							  , TargetTable.ProductKey = SourceTable.ProductKey
							  , TargetTable.OrderQty = SourceTable.OrderQty
  							  , TargetTable.ActualUnitPrice = SourceTable.ActualUnitPrice
					When Not Matched By Source 
						Then -- The CustomerID is in the Target table, but not the source table
							DELETE;
	  Set @RC = +1
	 END Try
	 Begin Catch
	  Print Error_Message()
	  Set @RC = -1
	 End Catch
	 Return @RC;
	END
Go
/* Testing data
 Declare @Status int;
 EXEC @Status = pETLSyncFactSalesOrders
 Print @Status;
 Select * From FactSalesOrders;
*/

--********************************************************************--
-- Review the results of this script
--********************************************************************--
Go
Declare @Status int = 0;

Exec @Status = pETLSyncDimProducts;
Select [Object] = 'pETLSyncDimProducts', [Status] = @Status;
Print @Status;

Exec @Status = pETLSyncDimCustomers;
Select [Object] = 'pETLSyncDimCustomers', [Status] = @Status;
Print @Status;

Exec @Status = pETLFillDimDates;
Select [Object] = 'pETLFillDimDates', [Status] = @Status;
Print @Status;

Exec @Status = pETLSyncFactSalesOrders;
Select [Object] = 'pETLSyncFactSalesOrders', [Status] = @Status;
Print @Status;


Go
Select * from [dbo].[DimProducts];
Select * from [dbo].[DimCustomers];
Select * from [dbo].[DimDates];
Select * from [dbo].[FactSalesOrders];

