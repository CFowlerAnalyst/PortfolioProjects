SELECT * 
FROM SalesProject..SupermarketSales

/*
Changing headers to remove spaces
*/
USE SalesProject
GO

EXEC sp_rename '.SupermarketSales.[customer type]', 'customer_type'
EXEC sp_rename '.SupermarketSales.[product line]', 'product_line'
EXEC sp_rename '.SupermarketSales.[unit price]', 'unit_price'
EXEC sp_rename '.SupermarketSales.[cost of goods sold]', 'cost_of_goods_sold'


/* 
Changing date column to conventional standard
*/

SELECT date, CONVERT(date,date)
FROM SalesProject..SupermarketSales

ALTER TABLE Salesproject..SupermarketSales
ALTER COLUMN date date


/*
Find the profit for the year to date and the difference from last year across all stores
*/

WITH profit_calc (profit_2020, profit_2021) AS
	(
	SELECT 
	SUM(CASE
		WHEN YEAR(date) = '2020' THEN profit
	END) AS profit_2020,
	SUM(CASE
		WHEN YEAR(date) = '2021' THEN profit
	END) AS profit_2021
	FROM SalesProject..SupermarketSales
	)

SELECT *, (profit_2021 - profit_2020) AS profit_difference
FROM profit_calc



/*
Calculating total profit per month for 2020 and 2021
*/

SELECT city, MONTH(date) month, SUM(profit) profit
FROM SalesProject..SupermarketSales
--WHERE city = 'Mandalay'
WHERE YEAR(date) = '2020'
GROUP BY city, MONTH(date)
ORDER BY city


SELECT city, MONTH(date) month, SUM(profit) profit
FROM SalesProject..SupermarketSales
--WHERE city = 'Mandalay'
WHERE YEAR(date) = '2021'
GROUP BY city, MONTH(date)
ORDER BY city


/*
Seeing unit sold and profit for each product line for each gender
*/

SELECT City, Product_line, gender, SUM(quantity) units_sold, SUM(profit) total_profit
FROM SalesProject..SupermarketSales
GROUP BY city, product_line, gender
ORDER BY city, product_line


/*
Breakdown of units sold and profit for members vs non members
*/

UPDATE SupermarketSales
SET customer_type = 'Non member'
WHERE customer_type = 'Normal'

SELECT customer_type, 
	SUM(quantity) units_sold,
	ROUND(SUM(quantity) * 100 / (SELECT SUM(quantity) FROM SalesProject..SupermarketSales), 2) AS percentage_units_sold,
	SUM(profit) total_profit,
	ROUND(SUM(profit) * 100 / (SELECT SUM(profit) FROM SalesProject..SupermarketSales), 2) AS percentage_profit,
	ROUND(AVG(rating), 1) avg_rating
FROM SalesProject..SupermarketSales
GROUP BY customer_type

SELECT customer_type, product_line, SUM(quantity) units_sold, SUM(profit) total_profit
FROM SalesProject..SupermarketSales
GROUP BY customer_type, product_line
ORDER BY customer_type, product_line 


/*
Looking at rating and any effect on profits
*/

SELECT branch, city, ROUND(AVG(rating), 2) avg_rating, SUM(profit) total_profit
FROM SalesProject..SupermarketSales
GROUP BY branch, city 
ORDER BY avg(rating)

SELECT city, ROUND(AVG(rating), 2) avg_rating, SUM(profit) total_profit, YEAR(date)
FROM SalesProject..SupermarketSales
--WHERE city = 'Yangon'
GROUP BY city, YEAR(date)
ORDER BY city