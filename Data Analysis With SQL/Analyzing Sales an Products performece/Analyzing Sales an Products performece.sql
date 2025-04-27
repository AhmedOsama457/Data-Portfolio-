select * from [gold.fact_sales] ;

-- scaning years total sales to take a look in the profits 

use sql_project;
select year(order_date) as DATE, sum(price) as Total_Sales , COUNT(distinct customer_key) as total_customers , SUM(quantity) as total_quantity
from [gold.fact_sales]
group by  year(order_date)
order by  year(order_date);

-- seeing which higher year in sales and which lower 

use sql_project;
select year(order_date) as DATE, sum(price) as Total_Sales , COUNT(distinct customer_key) as total_customers , SUM(quantity) as total_quantity
from [gold.fact_sales]
group by  year(order_date)
order by   sum(price);

-- to catch a trend lets see months sales from all years

use sql_project;
select month(order_date) as DATE, sum(price) as Total_Sales , COUNT(distinct customer_key) as total_customers , SUM(quantity) as total_quantity
from [gold.fact_sales]
group by   month(order_date)
order by  SUM(price);

-- cheking evrey year month

use sql_project;
select datetrunc(month , order_date) as DATE, sum(price) as Total_Sales , COUNT(distinct customer_key) as total_customers , SUM(quantity) as total_quantity
from [gold.fact_sales]
group by    datetrunc(month , order_date) 
order by   datetrunc(month , order_date) ;

-- Cumulative Analysis 
-- calculating the cumulative sales over time to see how the sales performece doing 

use sql_project;
select order_date , total_sales , 
SUM(total_sales) over(order by order_date) as cumulative
from 
(select DATETRUNC(month, order_date) as order_date , sum(sales_amount) as total_sales 
from [gold.fact_sales]
group by DATETRUNC(month, order_date)) sq

-- Cumulative Analysis 
-- For years  

use sql_project;
select order_date , total_sales , 
SUM(total_sales) over(order by order_date) as cumulative
from 
(select DATETRUNC(YEAR, order_date) as order_date , sum(sales_amount) as total_sales 
from [gold.fact_sales]
group by DATETRUNC(YEAR, order_date)) sq

-- adding the moving avrage to see the groth

use sql_project;
select order_date , total_sales , 
SUM(total_sales) over(order by order_date) as sales_growing,
avg(avg_price) over (order by order_date) as moving_avg
from 
(select DATETRUNC(month, order_date) as order_date , sum(sales_amount) as total_sales , AVG(price) as avg_price
from [gold.fact_sales]
group by DATETRUNC(month, order_date)) sq


-------------------------------------------------------------------------------PERFORMCE ANALYSIS------------------------------------------------------

-- Comparing the product sales to its avrage sales over years 

use sql_project;
with yearly_product_sales as
(select year(s.order_date) as order_year , p.product_name , SUM(sales_amount) as total_sales
from [gold.dim_products] p
left join [gold.fact_sales] s on p.product_key = s.product_key
where order_date is not null
group by year(order_date) , product_name
)
select order_year , product_name , total_sales , AVG(total_sales) over (partition by product_name)  as avg_product_sales , total_sales - AVG(total_sales) over (partition by product_name) as avg_diff,
case when total_sales - AVG(total_sales) over (partition by product_name) > 0 then 'Above Avrage'
	when total_sales - AVG(total_sales) over (partition by product_name) > 0 then 'Below Avrage'
	else 'Avg'
	end as product_sales_statment
from yearly_product_sales
order by product_name

 -- Comparing product sales to its sales in the previous year 

 use sql_project;
with yearly_product_sales as
(select year(s.order_date) as order_year , p.product_name , SUM(sales_amount) as total_sales
from [gold.dim_products] p
left join [gold.fact_sales] s on p.product_key = s.product_key
where order_date is not null
group by year(order_date) , product_name
)
select order_year , product_name , total_sales , AVG(total_sales) over (partition by product_name)  as avg_product_sales , total_sales - AVG(total_sales) over (partition by product_name) as avg_diff,
case when total_sales - AVG(total_sales) over (partition by product_name) > 0 then 'Above Avrage'
	when total_sales - AVG(total_sales) over (partition by product_name) > 0 then 'Below Avrage'
	else 'Avg'
	end as product_sales_statment,
lag(total_sales) over (partition by product_name order by order_year) as py_sales , total_sales - lag(total_sales) over (partition by product_name order by order_year) as sales_diff,
case when   total_sales - lag(total_sales) over (partition by product_name order by order_year) > 0 then 'Increase'
	when  total_sales - lag(total_sales) over (partition by product_name order by order_year) > 0 then 'Decrease'
	else 'No change'
	end as statment
from yearly_product_sales
order by product_name

----------------------------------------------------- The same analysis for categoryis 
use sql_project;
select Year , category , 
current_sales ,lag(current_sales) over (partition by category order by Year) as privious_sales, current_sales - lag(current_sales) over (partition by category order by Year) as diffrence,
AVG(current_sales) over (partition by category order by Year) as avr_sales, current_sales - AVG(current_sales) over (partition by category order by Year) as avrage_diff
from
(select year(order_date) as Year , category , sum(sales_amount) as current_sales
from [gold.fact_sales] s join [gold.dim_products] p 
on p.product_key = s.product_key
group by year(order_date) , category
)sq


-------------------------------------------------------------------------------------------PART TO ALL ANALYSIS ---------------------------------------------------------------------------------------


select product_line , product_line_sales , sum(product_line_sales) over() as total_sales , round((cast(product_line_sales as float)/ sum(product_line_sales) over()) * 100,2) as sales_percentege
from
(select product_line , sum(sales_amount) as product_line_sales
from [gold.fact_sales] s
join [gold.dim_products] p
on s.product_key = p.product_key
group by product_line) s1
order by  product_line_sales desc

-----------------------------------------------------------------------------------------DATA SEGMENTATION----------------------------------------------------------------------------------------


-- here we will analyize the data using mesures to mesures threw converting mesures to dimention using case 

select cost_range ,sum(sales_amount) as total_sales , sum(cost) as total_cost , sum(profit)  as total_profit 
from 
(select sales_amount , cost , sales_amount - cost as profit ,
case 
when cost < 100 then 'Below 100'
when cost between 100 and 500 then 'Between 100-500'
when cost between 500 and 1000 then 'Between 500-1000'
else 'Above 1000'
end as cost_range
from [gold.fact_sales] s
join [gold.dim_products] p
on s.product_key = p.product_key) sq
group by cost_range
order by  total_profit desc

----------------------------------------------------------------------------------------DATA SEGMENTATION-------------------------------------------------------------------------------------------

-- customer behavior

with customer_behavior as 
(
select  customer_id , COUNT(customer_id) as number_of_purchasing, sum(sales_amount) as total_spending , MIN(order_date) as first_process ,
MAX(order_date) as last_process , DATEDIFF(MONTH ,  MIN(order_date) ,  MAX(order_date) ) as life_span
from [gold.dim_customers] c
left join [gold.fact_sales] s
on c.customer_key = s.customer_key
group by customer_id)
select   customer_id ,  number_of_purchasing ,  total_spending ,first_process , last_process , life_span ,
case when life_span >= 12 and total_spending >= 5000 then 'VIP'
 when life_span >= 12 and total_spending < 5000 then 'Regular'
 else 'New'
 end as customer_level
from customer_behavior

-------- aggregation 



with customer_behavior as 
(
select  customer_id , COUNT(customer_id) as number_of_purchasing, sum(sales_amount) as total_spending , MIN(order_date) as first_process ,
MAX(order_date) as last_process , DATEDIFF(MONTH ,  MIN(order_date) ,  MAX(order_date) ) as life_span
from [gold.dim_customers] c
left join [gold.fact_sales] s
on c.customer_key = s.customer_key
group by customer_id)
select customer_level , COUNT(customer_level) as total_customers
from
(select   customer_id ,  number_of_purchasing ,  total_spending ,first_process , last_process , life_span ,
case when life_span >= 12 and total_spending >= 5000 then 'VIP'
 when life_span >= 12 and total_spending < 5000 then 'Regular'
 else 'New'
 end as customer_level
from customer_behavior)sq
group by customer_level
order by customer_level 
------------------------------------------------
-----------------------------------------------------------------------------------------------customer report -----------------------------------------------------------------------


create view customers_report as
with base as
(select s.order_number ,  s.order_date  , s.sales_amount , s.quantity,product_key , c.customer_key , c.customer_number , CONCAT(first_name,' ', last_name) as customer_name , c.birthdate , DATEDIFF(YEAR , birthdate , GETDATE()) as age
from [gold.fact_sales] s
left join [gold.dim_customers] c
on s.customer_key = c.customer_key)
select  customer_name , age , 
case when age < 25 then '<25 '
when age between 25 and 35 then '25-35'
when age between 35 and 45 then '35-45'
when age between 45 and 55 then '45-55'
else '>55'
end as age_range,
total_orders , total_sales , total_items , total_quantity ,
case when life_span >= 12 and total_sales >= 5000 then 'VIP'
 when life_span >= 12 and total_sales < 5000 then 'Regular'
 else 'New'
 end as customer_level,
 last_order_date , life_span , DATEDIFF(MONTH , last_order_date , GETDATE()) as recency ,
 total_sales / total_orders as avrege_order_value ,
 case when life_span = 0 then total_sales
 else total_sales / life_span 
 end as avrage_monthly_purchases
from
(select customer_number ,customer_name , age , COUNT(distinct order_number) as total_orders , SUM(sales_amount) as total_sales , count(distinct product_key) as total_items , SUM(quantity) as total_quantity , max(order_date) as last_order_date , DATEDIFF(MONTH, MIN(order_date), max(order_date)) as life_span
from base
group by customer_number , customer_name , age )sq


----------------------------------------------------------------------------------------------products report-------------------------------------------------------------------------------------------------------

create view product_report as 
with products_report as

(select order_number , s.product_key , customer_key , order_date , sales_amount , quantity , product_name , subcategory , cost 
from [gold.fact_sales]s
left join [gold.dim_products] p
on s.product_key = p.product_key)


select product_key , product_name , subcategory , number_of_customers ,total_orders , total_sales , total_sales - total_cost as total_profit , total_quantity_sold ,  DATEDIFF(MONTH , first_order , last_order ) as life_span,
case when total_sales > 50000 then 'High performed'
when total_sales between 10000 and 50000 then 'Mid performed'
else 'weak performed'
end as product_performence,
case when DATEDIFF(MONTH , first_order , last_order ) = 0 then 0
else total_sales / DATEDIFF(MONTH , first_order , last_order )
end as avrage_monthly_sales
from
(select product_key , product_name , subcategory ,  COUNT(distinct customer_key) as number_of_customers , SUM(sales_amount) as total_sales , SUM(quantity) as total_quantity_sold , count(distinct order_number) as total_orders
, SUM(cost) as total_cost , MIN(order_date) as first_order , MAX(order_date) as last_order 
from products_report
group by  product_key , product_name , subcategory )sq

