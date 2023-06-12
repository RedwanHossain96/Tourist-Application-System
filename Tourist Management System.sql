
--=============Database Create in Default Location--============================
Use master
Go
Declare @data_path nvarchar(256);
Set @data_path =(Select Substring(physical_name, 1, CHARINDEX(N'master.mdf',Lower(physical_name))-1)
		From master.sys.master_files
		Where database_id=1 and file_id=1);
Exec ('Create Database Tourist_Application_System
On Primary
(Name=Tourist_Application_System_Data, Filename=''' +@data_path+'Tourist_Application_System_Data.mdf'',size=25mb,maxsize=Unlimited,filegrowth=5%)
Log On
(Name=Tourist_Application_System_Log, Filename=''' +@data_path+'Tourist_Application_System_Log.ldf'',size=2mb,maxsize=25mb,filegrowth=1mb)'
);
Go

--=============Table Create--=================================================
Use Tourist_Application_System
Create Table Tour
(
TourId int primary Key identity,
TourName varchar(60) not null,
WhereFrom varchar(60) not null,
PlaceTo varchar(60) not null,
WhereToGo varchar(60) not null,
Duration varchar(60) not null,
FarePerPerson money,
vat as (FarePerPerson*0.15),
TourDescription varchar(256) not null
);
Go

Use Tourist_Application_System
Create Table TouristSpotDescription
(
Spotid int primary key identity,
Country varchar(40) not null,
City varchar(40) not null,
Description varchar(256) not null,
Areacode bigint not null,
);
Go

Use Tourist_Application_System
Create Table TouristInformation
(
TouristId int primary key identity, 
TouristFirstname nchar(60) not null,  
TouristLastname nchar(60) not null, 
TouristAddress varchar(100) not null, 
TouristAge int not null, 
NumberofTourist smallint not null, 
TouristPhoneNumber char(15) check((TouristPhoneNumber like'[0][1][1-9][0-9][0-9] [0-9][0-9][0-9] [0-9][0-9][0-9]')) not null, 
TouristEmailID varchar(60) check (TouristEmailID Like '%@gmail.com' or TouristEmailID Like '%@yahoo.com' ), 
Nationality varchar(40) not null,
TouristType nvarchar(50) not null
);
Go

Use Tourist_Application_System
Create Table HotelBooking
(
HotelbookID int primary key identity,
Hotelname varchar(60) not null, 
HotelType varchar(50) not null,
HotelPhoneNumber Char(15) Not Null  Check ((HotelPhoneNumber Like '[0][1][1-9][0-9][0-9] [0-9][0-9][0-9] [0-9][0-9][0-9]')),
HotelEmailID varchar(60) CHECK (HotelEmailID Like '%@gmail.com' or HotelEmailID Like '%@yahoo.com' ), 
Hotellocation nvarchar(256) not null, 
Fromdate date, 
Todate date, 
Hotelfare money, 
Bookdate date
);
Go

Use Tourist_Application_System
Create Table Transportationsystem
(
Transportid int primary key identity,
Localaltransportationsystem varchar(40) not null,
Internationaltransportationsystem varchar(256),
Localaltransportfare money,
Internationaltransportfare money,
TotalTransportfare as (Localaltransportfare+Internationaltransportfare)
);
Go

Use Tourist_Application_System
Create Table TourGuide
(
Guideid int primary key identity,
Guidename varchar(40) not null, 
Gender char(20) not null, 
Languagesknown varchar(40) sparse null, 
Guidephonenumber Char(15) check((Guidephonenumber like'[0][1][1-9][0-9][0-9] [0-9][0-9][0-9] [0-9][0-9][0-9]')) not null
);
Go

Use Tourist_Application_System
Create Table TourConfirmation
(
ConfirmationId int identity,
TourId int foreign Key references Tour(TourId),
Spotid int foreign Key references TouristSpotDescription(Spotid),
TouristId int foreign Key references TouristInformation(TouristId), 
HotelBookID int foreign Key references HotelBooking(HotelbookID),
Transportid int foreign Key references Transportationsystem(Transportid),
Guideid int foreign Key references TourGuide(Guideid),
);
Go

--=========Alter table(Add and Delete)=================
Alter table TourGuide
Add NId bigint
Go

Alter table TourGuide
Drop Column NId
Go

--==========Clustered and Non-clustered index===============
Use Tourist_Application_System
Create Clustered Index CIndex
On TourConfirmation(ConfirmationId)
Go

Create NonClustered Index NCIndex
On TourGuide(Guidename)
Go

--===========Create Sequence==================================
Use Tourist_Application_System
Create Sequence sq_project
As bigint
Start with 10 Increment by 10
Minvalue 10 Maxvalue 100000
Cycle Cache 10;
Go

--=========Scaler Function======================
Create function dbo.Fn_TotalVat(@TourId int)
Returns int
Begin
	Return
	(Select Sum(FarePerPerson) From Tour Where TourId= @TourId)
End
Go

Print dbo.Fn_TotalVat(1)
Go

--===============Tabular Function==============================
CREATE FUNCTION dbo.fn_Table(@Pkage varchar(20))
RETURNS TABLE 
AS
RETURN
(SELECT Tour.TourName,Tour.WhereFrom,Tour.WhereToGo,Tour.duration,Tour.FarePerPerson
FROM Tour
Join TourConfirmation
ON Tour.TourId=TourConfirmation.TourId
WHERE TourName= '@tname'
)
GO

--======================Create View=======================================
Create View vw_TourGuide
AS
Select *
From TourGuide
GO

Insert Into vw_TourGuide(Guidename,Gender,Guidephonenumber)
Values('Nijam','Male','01876 321 989'),('Mostofa','Male','01876 321 988'),('Samira','female','01876 321 986'),('Sara','female','01876 321 985')
Go

Select * From vw_TourGuide
Go

Drop View vw_TourGuide
Go

--======================Create View with schemabinding=======================================
Create View vw_TourConfirmation
AS
Select *
From TourConfirmation
GO

Select * From vw_TourConfirmation
Where ConfirmationId=1
GO

CREATE VIEW vw_Sch_TouristInformation
WITH SCHEMABINDING 
AS
SELECT Tour.TourId as [Tour Id] ,TourConfirmation.TotalTourCost as [Total Cost]
FROM dbo.Tour
join dbo.TourConfirmation 
ON Tour.TourId=TourConfirmation.TourId
GO

SELECT * FROM vw_Sch_TouristInformation
GO
--=====================DROP VIEW vw_SchemaBind=============================================
Drop VIEW vw_Sch_TouristInformation
GO

--=====================Create View WITH ENCRYPTION=========================================
CREATE VIEW vw_Tour
WITH ENCRYPTION 
AS 
SELECT TourId,TourName,WhereFrom ,PlaceTo,WhereToGo ,Duration,FarePerPerson,TourDescription
FROM Tour
Go

SELECT * FROM vw_Tour
GO

--==============INSTEAD OF DELETE Trigger======================================--
Create Trigger vw_TourConfirmation  
on vw_TourConfirmation  
instead of delete  
as  
	Begin  
		Declare @Id int  
		Select @Id = TouristInformation.TouristId    
		from TouristInformation   
		join deleted    
		on deleted.TouristId = TouristInformation.TouristId    
		if(@Id is NULL )    
		Begin    
			Raiserror('Invalid Tourist ID or Tourist ID not Exists', 16, 1)    
			Return    
		End  
		else   
		delete TouristInformation   
		from TouristInformation  
		join deleted  
		on TouristInformation.TouristId= deleted.TouristId  
	End 
Go

--============Create Procedure=========================
CREATE PROCEDURE sp_TouristInformation
@id int,
@address varchar(60)
AS
SELECT * 
FROM TouristInformation
WHERE TouristId = @id AND TouristAddress = @address
GO

--============TRUNCATE TABLE============================================================
TRUNCATE TABLE HotelBooking
Go

--===========Arithmetic Operators========================================================
SELECT 100000+200000 AS [Sum]
GO
SELECT 2000000-100000 AS [Substraction]
GO
SELECT 200*100 AS [Multiplication]
GO
SELECT 156/13 AS [Division]
GO
SELECT 78%8 AS [Remainder]
GO

---=================DML============================================
Use Tourist_Application_System
Go

Insert Into Tour(TourName,WhereFrom,PlaceTo,WhereToGo,Duration,FarePerPerson,TourDescription)
Values('Sightseeing Tours','Dhaka','Marine Drive','Cox''s Bazar','1 night 2 days',3000,'It is an amazing place to enjoy the beauty of the beach'),
	  ('Shore Excursion Tours','Chattogram','Cox''s Bazar Sea Beach','Cox''s Bazar','2 night 3 days',2000,'It is an amazing place to enjoy the beauty'),
	  ('Pilgrimage','Chattogram','Macca','Saudi Arabia','29 night 30 days',150000,'It is an amazing place to fresh the mind'),
	  ('Wedding Tour','Dhaka','Saint Martin Island','Cox''s Bazar','1 night 2 days',4000,'It is an amazing place to enjoy the beauty'),
	  ('Mountain Skiing Tour','Dhaka','Keokradong','Bandarban','2 night 3 days',5000,'It is an amazing place to enjoy the beauty')
Go


Insert Into TouristSpotDescription(Country,City,Description,Areacode)
Values('Bangladesh','Cox''s Bazar','Cox''s Bazar is famous for its longest unbroken sandy sea beach',4700),
	  ('Bangladesh','Bandarban','It is one of the three hill districts of Bangladesh and a part of the Chittagong Hill Tracts',4600 ),
	  ('Bangladesh','Sylhet','During Bangladesh''s monsoon and rainy season, Sylhet Tour is the ideal place to vacation',3100),
	  ('Saudi Arabia','Macca',' Is a city and administrative center of the Mecca Province of Saudi Arabia, and the holiest city in Islam',442 )
Go

Insert Into TouristInformation(TouristFirstname,TouristLastname,TouristAddress,TouristAge,NumberofTourist,TouristPhoneNumber,TouristEmailID,Nationality,TouristType)
Values('Abdullah','Mohammad','Dhaka',30,4,'01853 478 915','abdullah@gmail.com','Bangladeshi','National'),
	  ('Faysal','Wahid','Maymansingh',38,15,'01853 478 913','wahid@gmail.com','Bangladeshi','National'),
	  ('Gias','Uddin','Chattogram',26,4,'01853 478 925','gias@yahoo.com','Bangladeshi','National'),
	  ('Fateh','Mohammad','Saudia Arabia',43,2,'01853 478 715','fateh@gmail.com','Saudi Arabian','Inter national')
Go

Insert Into HotelBooking(Hotelname,HotelType,HotelPhoneNumber,HotelEmailID,Hotellocation,Fromdate,Todate,Hotelfare,Bookdate)
Values ('Hotel The Cox Today',' 5 star','01755 598 449','reservation@gmail.com','Cox''s Bazar','2022-10-19','2022-10-22',5000,'2022-10-10'),
	   ('ABC',' 4 star','01755 598 409','abc@gmail.com','Cox''s Bazar','2022-10-22','2022-10-25',3000,'2022-10-18'),
	   ('XYZ', '5 star','01755 598 440','xyz@gmail.com','Sylhet','2022-10-19','2022-10-22',5500,'2022-10-15'),
	   ('EFG',' 3 star','01755 598 445','efg@gmail.com','BandarBan','2022-11-19','2022-11-22',5000,'2022-10-15'),
	   ('HIJ',' 5 star','01755 598 349','hijn@yahoo.com','sylhetr','2022-11-25','2022-11-27',5000,'2022-10-22')
Go

Insert Into Transportationsystem(Localaltransportationsystem,Internationaltransportationsystem,Localaltransportfare,Internationaltransportfare)
Values('Bus','Airplane','2000','50000'),
	  ('Car','Airplane','5000','60000'),
	  ('Train','Airplane','1000','40000'),
	  ('CNG','','3000','')
Go

Insert Into TourGuide(Guidename,Gender,Languagesknown,Guidephonenumber)
Values('Alif','Male','Bangla,English','01789 987 654'),
	  ('Asifa','Feale','Bangla,English,Arabic','01789 989 654'),
	  ('Adib','Male','Bangla,English,Spanish','01789 988 655'),
	  ('Adiba','Female','Bangla,English,French','01788 987 654'),
	  ('Arman','Male','English,French,Arabic','01889 987 654')
Go

--===============Update statement--=================
Update TourGuide
Set Guidename='Ayman'
Where Guidephonenumber='01889 987 654'
Go

DELETE FROM TourGuide 
WHERE Guidename='Ayman'
Go

Insert Into TourConfirmation(TourId,Spotid,TouristId,HotelBookID,Transportid,Guideid,TotalTourCost)
Values(1,1,1,1,1,1,100000),
	  (1,1,1,1,1,1,80000),
	  (1,1,1,1,1,1,120000),
	  (1,1,1,1,1,1,10000)	  
Go

Select * from Tour
Select * from TouristSpotDescription
Select * from TouristInformation
Select * from HotelBooking
Select * from Transportationsystem
Select * from TourGuide
Select * from TourConfirmation
Go

--=========-- Basic Six Clauses============================
Select ConfirmationId,Count(TourId) as [Tour Id]
From TourConfirmation
Where ConfirmationId>4
Group By TouristId
HAVING COUNT(TourId)>1
Order By TotalTourCost Desc
Go

--================Create Sub Query==========================================
SELECT avg(TotalTourCost) as [avg Cost]
FROM TourConfirmation
WHERE TotalTourCost in(SELECT TotalTourCost FROM TourConfirmation WHERE TourId>=4)
GO

--==================Cast and Convert==================================================

SELECT 'Today :'+ CAST(GETDATE() as varchar)
Go
SELECT 'Today :'+ CONVERT(varchar,GETDATE())
Go
SELECT 'Today :'+ CONVERT(varchar,GETDATE(),1)
Go
SELECT 'Today :'+ CONVERT(varchar,GETDATE(),2)
GO

--===================CTE===========================================================
WITH cte_TourGuide (Guideid,Guidename,Gender,Languagesknown,Guidephonenumber)
AS
(
SELECT Guideid,Guidename,Gender,Languagesknown,Guidephonenumber
FROM TourGuide 
WHERE Guideid >=4
)
SELECT * FROM cte_TourGuide
Go

--Left Outer Join
SELECT T.TourId,T.TourName,T.Duration,C.TotalTourCost
FROM Tour T
LEFT JOIN TourConfirmation C
ON T.TourId=C.TourId
GO

--===========Right Outer Join==================
SELECT D.Spotid,D.Description,C.ConfirmationId,C.TotalTourCost
From TouristSpotDescription D
RIGHT JOIN TourConfirmation C
ON D.Spotid=C.Spotid
GO

--=====Full Outer Join==================
SELECT I.TouristId,I.TouristFirstname,I.TouristPhoneNumber,I.TouristAddress,C.ConfirmationId
FROM TouristInformation I
FULL JOIN TourConfirmation C
ON I.TouristId=C.TouristId
GO

--=====================Cross Join============================
SELECT B.HotelbookID,B.Bookdate,C.ConfirmationId,C.TotalTourCost
FROM HotelBooking B
CROSS JOIN TourConfirmation C
GO

--=========Self Join=============================
SELECT I.TouristFirstname,I.TouristAge,I.Nationality,T.TouristAddress,T.TouristPhoneNumber
FROM TouristInformation AS I,TouristInformation AS T
WHERE I.TouristID=T.TouristID
GO

--=============Union=======================
SELECT I.TouristId,I.NumberofTourist FROM TouristInformation I
UNION 
SELECT C.TourId,C.HotelBookID FROM TourConfirmation C
GO

--=============Union all=======================
SELECT I.TouristId,I.NumberofTourist FROM TouristInformation I
UNION All
SELECT C.TourId,C.HotelBookID FROM TourConfirmation C
GO

--======================Distinct===========================================
SELECT DISTINCT Transportid,Localaltransportationsystem
FROM Transportationsystem
GO

--====================WildCard===============================================
SELECT *
FROM TourGuide
WHERE Guidephonenumber Like '018___%' or Guidephonenumber Like '017___%' or Guidephonenumber Like '019___%'  or Guidephonenumber Like '015___%'  or Guidephonenumber Like '016___%'
Go

--================Aggregate function======================================
SELECT COUNT (*) FROM TourConfirmation
SELECT AVG (TotalTransportfare) FROM Transportationsystem
SELECT MIN (TotalTransportfare) FROM Transportationsystem
SELECT MAX (Languagesknown) FROM TourGuide
Go

--===================--Cube, Rollup, Grouping Set===========================--
SELECT TourId,SUM(TotalTourCost) AS Spot
FROM TourConfirmation
GROUP BY TourId,TotalTourCost WITH CUBE
GO

SELECT TourId,SUM(TotalTourCost) AS Spot
FROM TourConfirmation
GROUP BY TourId,TotalTourCost WITH ROLLUP
GO

SELECT TourId,SUM(TotalTourCost) AS Spot
FROM TourConfirmation
GROUP BY Grouping Sets(TourId,TotalTourCost) 
GO

--================While Loop===========================================
DECLARE @a int
SET @a=1
WHILE @a<=5
BEGIN
		PRINT 'Enjoyable Tour : ' + CAST(@a as Varchar)
		SET @a=@a+1
END
GO

--================Case=============================================
SELECT ConfirmationId, TourId ,
	CASE
	WHEN TotalTourCost >50000 THEN 'Total Tour Cost is Tolerable'
	WHEN TotalTourCost=50000 THEN 'Total Tour Cost is is 50000'
	ELSE 'The Package in Under then 20000'
END	AS [Tour Confirm] 
FROM TourConfirmation
GO

--===============Round,Ceiling,Floor===============================
DECLARE @value int;
SET @value= 10;
SELECT ROUND (@value,1) As [Round];
SELECT CEILING (@value)  As [Ceilling];
SELECT FLOOR (@value) As [Floor];
GO

--=================Function======================
select IIF(TotalTourCost>50000,'Tour Confirm','Tour Rejected') as [Tour Confirmation]
From TourConfirmation
Go

Select Coalesce ('Alif','Asifa') as Guide
From TourGuide
Go

Select IsNull ('Alif','Asifa') [Guide Name]
From TourGuide
Go

Select ROW_NUMBER () Over(Partition By (TouristId) Order By(TouristId)) as Tourist From TouristInformation
Go

Select Rank () Over(Partition By (TouristId) Order By(TouristId)) as Tourist From TouristInformation
Go

Select Dense_Rank () Over(Partition By (TouristId) Order By(TouristId)) as Tourist From TouristInformation
Go

Select Ntile (3) Over(Partition By (TouristId) Order By(TouristId)) as Tourist From TouristInformation
Go

Select First_Value (Transportid) Over(Partition By (Transportid) Order By(Transportid)) as Transport From Transportationsystem
Go

Select Last_Value (Transportid) Over(Partition By (Transportid) Order By(ItemId)) as Transport From Transportationsystem
Go

--===Lead--===--
Select TotalTourCost,
	Lead (TotalTourCost) Over(Order By(TotalTourCost) Desc) As Cost
From TourConfirmation
Go

--===LAG--==
Select * ,
	LAG (TotalTourCost,1)Over(Order By(TotalTourCost) Asc) As [Cost]
From TourConfirmation
Go

--=========Percent_Rank=====================
SELECT TourId,Spotid,TouristId,   
       Percent_Rank()  OVER ( Partition By TourId ORDER BY TotalTourCost) AS[Tour Percent]
From TourConfirmation
Go
--=============CUME_DIST=======================
SELECT TourId,Spotid,TouristId,   
       CUME_DIST()  OVER ( Partition By TourId ORDER BY TotalTourCost) AS [Tour Dist]
From TourConfirmation
Go

--==================Raiseerror===========================================
Select * From master .sys.messages

select * from sys.messages where message_id=550

Raiserror (60000,7,1,'computer')

 --====Insert Raiserror message--===========================================
 exec sp_addmessage
 @msgnum=70000,
 @severity=10,
 @msgtext=  '%s is not a valid order date.
        Order date must be within 7 days of current dates';

--calling custom message--
Raiserror (70000,10,1, 'computer')

Select *
From sys.messages
Where message_id=70000
Go

--==========drop custom message==================================
exec sp_dropmessage 70000
Go

