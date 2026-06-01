USE nike_sales;

CREATE TABLE clean_sales LIKE uncleaned_sales;

INSERT INTO clean_sales
SELECT*
FROM uncleaned_sales ;

SELECT*
FROM clean_sales ;


	-- lets check for duplicates 
    
WITH nike_clt AS (SELECT*,
ROW_NUMBER() OVER(PARTITION BY Order_ID,Gender_Category,Product_Line,Product_Name,Size,Units_Sold,MRP,Discount_Applied,
Revenue,Order_Date,Sales_Channel,Region,Profit) AS row_num
FROM clean_sales)
SELECT*
FROM nike_clt
WHERE row_num > 1 ;

	---- Checking for empty rows and null
SELECT* 
FROM clean_sales
WHERE Size= '' OR Size = NULL ;
 ;

UPDATE clean_sales
SET Size = NULL
WHERE Size = '' ;

SET SQL_SAFE_UPDATES = 0 ;

SELECT* 
FROM clean_sales
WHERE Units_Sold= '' OR Units_Sold = NULL ;

UPDATE clean_sales
SET Units_Sold = NULL
WHERE Units_Sold = '' ;

SELECT* 
FROM clean_sales
WHERE MRP= '' OR MRP= NULL ;

UPDATE clean_sales
SET MRP = NULL
WHERE MRP = '' ;

---- Lets update all together 

UPDATE clean_sales
SET
Discount_Applied = CASE 
						WHEN Discount_Applied = '' THEN NULL
                        ELSE Discount_Applied
					END,
Revenue = CASE 
						WHEN Revenue = '' THEN NULL
                        ELSE Revenue
                        END,
 Order_Date = CASE 
						WHEN Order_Date = '' THEN NULL
                        ELSE Order_Date
                        END,                       
Sales_Channel = CASE 
						WHEN Sales_Channel = '' THEN NULL
                        ELSE Sales_Channel
                        END,
Region = CASE 
						WHEN Region = '' THEN NULL
                        ELSE Region
                        END,
Profit= CASE 
						WHEN Profit = '' THEN NULL
                        ELSE Profit
                        END;

 SELECT*
 FROM clean_sales;


---- change null discount to zero

UPDATE clean_sales
SET Discount_Applied = 0
WHERE Discount_Applied IS NULL;

---- correction of data type

ALTER TABLE clean_sales
MODIFY COLUMN Size VARCHAR(10) ;

ALTER TABLE clean_sales
MODIFY COLUMN Units_Sold INT ;

ALTER TABLE clean_sales
MODIFY COLUMN MRP DECIMAL(10,2) ;

ALTER TABLE clean_sales
MODIFY COLUMN Discount_Applied DECIMAL(10,2) ;

ALTER TABLE clean_sales
MODIFY COLUMN Discount_Applied DECIMAL(10,2) ;

ALTER TABLE clean_sales
ADD COLUMN Order_Date_cleaned DATE ;

UPDATE clean_sales
SET Order_Date_cleaned =
CASE
    -- format: YYYY-MM-DD
    WHEN Order_Date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
        THEN STR_TO_DATE(Order_Date, '%Y-%m-%d')

    -- format: DD-MM-YYYY
    WHEN Order_Date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
        THEN STR_TO_DATE(Order_Date, '%d-%m-%Y')

    -- format: MM/DD/YYYY
    WHEN Order_Date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
        THEN STR_TO_DATE(Order_Date, '%m/%d/%Y')

    ELSE NULL
END ;


SELECT *
FROM clean_sales;

ALTER TABLE clean_sales
MODIFY COLUMN Profit DECIMAL(10,2);

ALTER TABLE clean_sales
ADD COLUMN Revenue_Calculated INT;

SELECT*, Units_Sold*MRP*(1-Discount_Applied) AS Revenue_Calculated
FROM clean_sales ;

UPDATE clean_sales 
SET Revenue_Calculated = Units_Sold*MRP*(1-Discount_Applied);

SELECT Revenue, Revenue_Calculated
FROM  clean_sales ;

ALTER TABLE clean_sales
ADD COLUMN Size_Cleaned VARCHAR(50);

UPDATE clean_sales
SET Size_cleaned = CASE 
    WHEN size REGEXP '^[0-9]+$' THEN CONCAT('Shoe Size ', size)
    ELSE size
END;

SELECT*
FROM clean_sales ;

--- Standardization & Trimming
-- trimming
UPDATE clean_sales
SET Order_ID = TRIM(Order_ID),
Gender_Category =TRIM(Gender_Category),
Product_Line =TRIM(Product_Line),
Product_Name =TRIM(Product_Name), 
Size = TRIM(Size), 
Units_Sold =TRIM(Units_Sold),
MRP=TRIM(MRP), 
Discount_Applied =TRIM(Discount_Applied),
Revenue =TRIM(Revenue), 
Order_Date=TRIM(Order_Date),
Sales_Channel =TRIM(Sales_Channel),
Region=TRIM(Region), 
Profit=TRIM(Profit), 
Order_Date_cleaned =TRIM(Order_Date_cleaned),
Revenue_Calculated=TRIM(Revenue_Calculated),
Size_Cleaned=TRIM(Size_Cleaned);
    
SELECT*
FROM clean_sales ;

SELECT DISTINCT Region
FROM clean_sales;

UPDATE clean_sales
SET Region = 'Hyderabad'
WHERE Region = 'hyderbad';

UPDATE clean_sales
SET Region = 'Bengaluru'
WHERE Region = 'bengaluru';


SELECT DISTINCT Size_Cleaned
FROM clean_sales;

SELECT DISTINCT Sales_Channel
FROM clean_sales;

SELECT DISTINCT Gender_Category
FROM clean_sales;

SELECT DISTINCT Product_Name
FROM clean_sales;

SELECT DISTINCT Product_Line
FROM clean_sales;


SELECT*
FROM clean_sales;
ALTER TABLE clean_sales
MODIFY COLUMN Discount_Applied DECIMAL(5,2);

---- EDA

--  revenue trend
SELECT YEAR(Order_Date_cleaned) AS year, SUM(Profit)
FROM clean_sales
WHERE YEAR(Order_Date_cleaned) IS NOT NULL
GROUP BY YEAR(Order_Date_cleaned);

-- which product sells the most 

SELECT Product_Name, count(*) AS count
FROM clean_sales
GROUP BY Product_Name
ORDER BY count DESC ;

--- product with the most profit

SELECT Product_Name, SUM(Profit) AS total_profit
FROM clean_sales
GROUP BY Product_Name
ORDER BY total_profit DESC ;

-- which customer type spends the most
SELECT Gender_Category, SUM(Profit) AS total_profit
FROM clean_sales
GROUP BY Gender_Category
ORDER BY total_profit DESC ;

--- revenue per year
SELECT YEAR(Order_Date_Cleaned) AS Year , SUM(Profit) AS total_profit
FROM clean_sales
WHERE 'YEAR(Order_Date_Cleaned)' IS NOT NULL
GROUP BY Year
ORDER BY total_profit DESC ;

--- product performance per region

SELECT Region, SUM(Profit) AS total_profit
FROM clean_sales
GROUP BY Region
ORDER BY total_profit DESC ;

SELECT Region, COUNT(*) AS unit_sold
FROM clean_sales
GROUP BY Region
ORDER BY unit_sold DESC ;

-- Online Vs retail channel

SELECT Sales_Channel, SUM(Profit) AS total_profit
FROM clean_sales
WHERE Order_Date_cleaned IS NOT NULL
GROUP BY Sales_Channel
ORDER BY total_profit DESC ;

SELECT Sales_Channel, COUNT(*) AS count
FROM clean_sales
GROUP BY Sales_Channel
ORDER BY count DESC ;

--- Discount VS profit relationship
SELECT MAX(Discount_Applied) AS Discount
FROM clean_sales ;

SELECT*
FROM clean_sales
WHERE Discount_Applied > 1 ;

SELECT COUNT(*) AS invalid_discount
FROM clean_sales
WHERE Discount_Applied > 1 ;

UPDATE clean_sales
SET Discount_Applied = NULL
WHERE Discount_Applied > 1 ;


SELECT
		CASE 
        WHEN Discount_Applied = 0 THEN 'No Discount'
        WHEN Discount_Applied <= 0.2 THEN 'Low'
        WHEN Discount_Applied >= 0.5 THEN 'Medium'
        ELSE 'High'
END AS discount_group,
AVG(Profit) AS avg_profit
FROM clean_sales
WHERE Discount_Applied IS NOT NULL
GROUP BY discount_group
;
 
--- LETS TAKE A LOOK AT THE NEGATIVES SALES
 -- Check units sold 
 SELECT COUNT(*) AS negative_units
 FROM clean_sales
 WHERE Units_Sold < 0;

--- check revenue
SELECT COUNT(*) AS negative_revenue
 FROM clean_sales
 WHERE Revenue_Calculated < 0;

-- check profit
 SELECT COUNT(*) AS negative_profit
 FROM clean_sales
 WHERE Profit < 0;
 
 
 --- viewing
 SELECT*
 FROM clean_sales
 WHERE Units_Sold < 0 OR Profit < 0 OR Revenue_Calculated < 0 ;


SELECT*
 FROM clean_sales
 WHERE Units_Sold < 0 OR Profit < 0 OR Revenue_Calculated < 0 ;

SELECT AVG(Discount_Applied),AVG(Profit)
 FROM clean_sales
 WHERE Profit < 0  ;

-- Lets check the category that made the most loss
SELECT Product_Line, COUNT(*) AS loss_orders
 FROM clean_sales
 WHERE Profit < 0
 GROUP BY Product_Line
 ORDER BY loss_orders DESC;

SELECT Product_Line
 FROM clean_sales
 GROUP BY Product_Line;

SELECT 
SUM(Profit) AS total_profit,
SUM(CASE WHEN Profit < 0 THEN Profit ELSE 0 END) AS loss_from_negatives
FROM clean_sales;

SELECT 
SUM(Profit) AS total_profit,
SUM(CASE WHEN Profit < 0 THEN Profit ELSE 0 END) AS loss_from_negatives,
SUM(CASE WHEN Profit > 0 THEN Profit ELSE 0 END) AS positive_profit
FROM clean_sales;

SELECT*
FROM clean_sales;





































































































