
Select top 100 * from Earthquakes order by time asc


-- Get understanding of how many earthquakes there was since 1900

select count(DateTime) as TotalEarthquakes from Earthquakes 



-- Per country

select country, count(time)as TotalEarthquakes from Earthquakes 
group by Country
order by TotalEarthquakes desc


-- MONTHLYTOTALS
-- Split into years and months and group accordingly
-- Save to VIEW MonthlyTotals
DROP View if exists MonthlyTotals
go
Create View MonthlyTotals as
select DATEPART(year, time) as Year, DATEPART(month, time) as Month, country , count(time) as TotalEarthquakes from Earthquakes
where country is not NULL
group by DATEPART(year, time), DATEPART(month, time), country

--order by DATEPART(year, time) desc, DATEPART(month, time) desc, 4 desc



--ANNUALTOTALS
-- Split into years and months and group accordingly
-- Save to VIEW AnnualTotals
DROP View if exists AnnualTotals
go
Create View AnnualTotals as
select DATEPART(year, time) as Year,  country , count(time) as TotalEarthquakes from Earthquakes
where country is not NULL
group by DATEPART(year, time), country
--order by 1 desc,2 asc



-- Prepare data to previous years (per country)


SELECT cast(DATEPART(year, time) as float) as Year,
       country,
		cast(count(time)as float) as TotalEarthquakes,
       ((cast(count(time)as float)/lag(cast(count(time)as float), 1) OVER (ORDER BY DATEPART(year, time) asc)) - 1) * 100 AS percentage_change
FROM Earthquakes
--where country = 'Alaska'
group by DATEPART(year, time), country
ORDER BY DATEPART(year, time) asc


-- Create TEMP table to fix percentage problem
-- positive values are calculated differently than negative values (+100%)
DROP table if exists TEMPAnnualTotals
go
SELECT cast(DATEPART(year, time) as float) as Year,
       country,
		cast(count(time)as float) as TotalEarthquakes,
       ((cast(count(time)as float)/lag(cast(count(time)as float), 1) OVER (ORDER BY country asc)) - 1) * 100 AS percentage_change INTO TEMPAnnualTotals
FROM Earthquakes
--where country = 'Alaska'
group by DATEPART(year, time), country
ORDER BY country, DATEPART(year, time) asc

-- Fix wrong positive percentage values by adding 100%

Update TEMPAnnualTotals set percentage_change = (percentage_change+100) where percentage_change > 0

-- First row for each country needs to be NULL

SELECT row_number() OVER (PARTITION BY grp ORDER BY Country) AS number,
  *
FROM (
  SELECT count(rst) OVER (ORDER BY Country) AS grp, *
  FROM (
    SELECT CASE WHEN Country != lag(Country) OVER (ORDER BY Country) THEN 1 END AS rst, *
    FROM TEMPAnnualTotals
  ) AS t1
) AS t2;


Update TEMPAnnualTotals set percentage_change = NULL where lag(tempannualtotals.country, 1)<>country

DROP view if exists AnnualTotals
go
Create View AnnualTotals as
select * from TEMPAnnualTotals








-- Prepare to previous year (total)

SELECT cast(DATEPART(year, time) as float) as Year,
		cast(count(time)as float) as TotalEarthquakes,
       ((cast(count(time)as float)/lag(cast(count(time)as float), 1) OVER (ORDER BY DATEPART(year, time) asc)) - 1) * 100 AS percentage_change
FROM Earthquakes
where country is not NULL
group by DATEPART(year, time)
ORDER BY DATEPART(year, time) asc



-- Create Views for some of the above SELECT statements