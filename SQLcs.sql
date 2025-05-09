Select Top 1 * from DIM_CUSTOMER
Select TOP 1 * from DIM_DATE
Select TOP 1 * from DIM_LOCATION
Select TOP 1 * from DIM_MANUFACTURER
Select TOP 1 * from DIM_MODEL
select Top 1 * from FACT_TRANSACTIONS
--1 . List all the states in which we have customers who have bought cellphones  
--from 2005 till today. 
select Distinct d.State from FACT_TRANSACTIONS as f
join DIM_LOCATION as d
on d.IDLocation = f.IDLocation
where f.Date > '2005-01-01'

--2 . What state in the US is buying the most 'Samsung' cell phones?   
select D.State, COUNT(*) as Total_sales from DIM_LOCATION as D
join FACT_TRANSACTIONS as f on f.IDLocation = D.IDLocation
join DIM_MODEL as M on M.IDModel = M.IDModel
join DIM_MANUFACTURER as Dm on Dm.IDManufacturer = M.IDManufacturer
where Dm.Manufacturer_Name = 'samsung' and D.Country = 'US'
group by D.State

--3 . Show the number of transactions for each model per zip code per state.  
select m.Model_Name,D.ZipCode,D.State, COUNT(*) as No_Of_Transaction
from FACT_TRANSACTIONS as f
join DIM_LOCATION as D on D.IDLocation = f.IDLocation
join DIM_MODEL as m on m.IDModel = f.IDModel
group by m.Model_Name, D.ZipCode, D.State

--4 . Show the cheapest cellphone (Output should contain the price also) 
select m.Model_Name, f.TotalPrice as price from FACT_TRANSACTIONS as f
join DIM_MODEL as m on m.IDModel = f.IDModel
group by m.Model_Name, f.TotalPrice
order by price asc

--5 . Find out the average price for each model in the top5 manufacturers in terms of sales quantity and order by average price.   d
Begin 
with TOP5Manufacturers As(
select top 5 m.IDManufacturer
from FACT_TRANSACTIONS as f
join DIM_MODEL as d on d.IDModel = f.IDModel
join DIM_MANUFACTURER as m on m.IDManufacturer = d.IDManufacturer
group by m.IDManufacturer
Order by COUNT(*) Desc
)

select d.Model_Name, AVG(f.TotalPrice) as AveragePrice 
from FACT_TRANSACTIONS f
join DIM_MODEL as d on d.IDModel = f.IDModel
where d.IDManufacturer in (select IDManufacturer from TOP5Manufacturers)
group by d.Model_Name
order by AveragePrice
end



--6 . List the names of the customers and the average amount spent in 2009, where the average is higher than 500
select C.Customer_Name, AVG(f.TotalPrice) as AveragePrice
from DIM_CUSTOMER as C
join FACT_TRANSACTIONS as f on f.IDCustomer = C.IDCustomer
where YEAR(f.Date) = '2009'
group by C.Customer_Name
having AVG(f.TotalPrice) > 500

--7 . List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010   
Begin 
with Top5_2008 as( 
select top 5 m.IDModel
from DIM_MODEL as m
join FACT_TRANSACTIONS as f on f.IDModel = m.IDModel
where YEAR(f.date) = '2008'
group by m.IDModel
order by COUNT(*) DESC
),
Top5_2009 as (
select Top 5 m.IDModel
from dim_Model as m
join FACT_TRANSACTIONS as f on f.IDModel = m.IDModel
where YEAR(f.Date) = '2009'
group by m.IDModel
order by COUNT(*) DESC
),
top10_2010 as (
select top 5 m.IDModel
from DIM_MODEL as m
join FACT_TRANSACTIONS as f on f.IDModel = m.IDModel
where YEAR(f.Date) = '2010'
group by m.IDModel
order by COUNT(*) DESC
)
select m.IDModel
from DIM_MODEL as m
where m.IDModel in (select m.IDModel from Top5_2008)
and m.IDModel in (select m.IDModel from Top5_2009)
and m.IDModel in (select m.IDModel from top10_2010);
end

--8 . Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010.  
begin 
with sales_2009 as (
select dm.Manufacturer_Name, COUNT(*) as total_sales,
ROW_NUMBER() over(order by count(*) Desc) as rank_2009
from FACT_TRANSACTIONS as f
join DIM_MODEL as m on m.IDModel = f.IDModel
join DIM_MANUFACTURER as dm on dm.IDManufacturer = m.IDManufacturer
where YEAR(f.Date) = '2009'
group by dm.Manufacturer_Name
),
sales_2010 as(
select dm.Manufacturer_Name, COUNT(*) as total_sales,
ROW_NUMBER() over( order by count(*) Desc) as rank_2010
from FACT_TRANSACTIONS as f
join DIM_MODEL m on m.IDModel = f.IDModel
join DIM_MANUFACTURER dm on dm.IDManufacturer = m.IDManufacturer
where YEAR(f.Date) = '2010'
group by dm.Manufacturer_Name
)
select s1.Manufacturer_Name as Second_top_2009, s2.Manufacturer_Name as second_top_2010
from sales_2009 s1
join sales_2010 s2 on s1.Manufacturer_Name = s1.Manufacturer_Name
where s1.rank_2009=2  and s2.Manufacturer_Name = 2
end


--9 . Show the manufacturers that sold cellphones in 2010 but did not in 2009.  
begin
select Distinct dm.Manufacturer_Name 
from FACT_TRANSACTIONS f
join DIM_MODEL as m on m.IDModel = f.IDModel
join DIM_MANUFACTURER as dm on m.IDManufacturer = dm.IDManufacturer
where YEAR(f.Date) = '2010' 
and dm.IDManufacturer not in ( select Distinct dm.IDManufacturer from FACT_TRANSACTIONS f
                               join DIM_MODEL m on m.IDModel = f.IDModel
							   join DIM_MANUFACTURER dm on dm.IDManufacturer = m.IDManufacturer
							   where YEAR(f.Date) = '2009'
							   );
end


--10 . Find top 100 customers and their average spend, average quantity by each  year. Also find the percentage of change in their spend. 
begin 
with TotalSpend as (
select c.IDCustomer, YEAR(f.Date) as year, AVG(f.TotalPrice) as Avg_Price, AVG(f.Quantity) as Avg_auantity
from FACT_TRANSACTIONS f
join DIM_CUSTOMER c on c.IDCustomer = f.IDCustomer
group by c.IDCustomer, YEAR(f.Date)
),
with 100Customer as (
select top 100 s.IDCustomer
from TotalSpend s
join DIM_CUSTOMER c on c.IDCustomer = s.IdCustomer
order by SUM(TotalSpend) Desc
)
