-- The data are organized into 5 tables customers , invintory, invoices , orders , products 
-- we will link the tables using joins 
-- and we will find the total sales and profit and sales by countries .... , and then we will store them in veiws to export them to tablue for visualization;  
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- view for profits

create view tota_sales_and_profit as
select product_id , product_name ,total_sales_perunit , product_price ,product_cost ,total_products_sales ,  total_products_costs , total_products_sales - total_products_costs as total_products_profit
from
(select product_id , product_name ,total_sales_perunit , product_price ,product_cost , total_sales_perunit * product_price as total_products_sales , total_sales_perunit * product_cost as total_products_costs
from 
(select p.product_id , p.product_name , sum(quantity) as total_sales_perunit ,product_price ,i.product_cost
from produts p 
join orders o using(product_id)
join invintory i using (product_id)
group by p.product_id 
order by product_id)s1)s2;
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- view for sales by countries 

create view sales_by_countries as
select country ,  sum(customers_sales) as sales_by_country 
from
(select customer_id , country , quantity , product_price , quantity * product_price as customers_sales
from customers 
join orders using (customer_id)
join produts using(product_id))s1
group by country 
order by country;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- view for customers purchases

CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER

VIEW `customers_purchases` AS
    SELECT 
        `s1`.`customer_id` AS `customer_id`,
        `s1`.`first_name` AS `first_name`,
        `s1`.`last_name` AS `last_name`,
        SUM(`s1`.`clients_sales`) AS `total_clients_sales`
    FROM
        (SELECT 
            `o`.`order_id` AS `order_id`,
                `c`.`customer_id` AS `customer_id`,
                `c`.`first_name` AS `first_name`,
                `c`.`last_name` AS `last_name`,
                `o`.`quantity` AS `quantity`,
                `p`.`product_name` AS `product_name`,
                `p`.`product_price` AS `product_price`,
                (`o`.`quantity` * `p`.`product_price`) AS `clients_sales`
        FROM
            ((`orders` `o`
        JOIN `customers` `c` ON ((`o`.`customer_id` = `c`.`customer_id`)))
        JOIN `produts` `p` ON ((`o`.`product_id` = `p`.`product_id`)))) `s1`
    GROUP BY `s1`.`customer_id`
    ORDER BY `s1`.`customer_id`;
    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- view for total sales and profits
    
    CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `tota_sales_and_profit` AS
    SELECT 
        `s2`.`product_id` AS `product_id`,
        `s2`.`product_name` AS `product_name`,
        `s2`.`total_sales_perunit` AS `total_sales_perunit`,
        `s2`.`product_price` AS `product_price`,
        `s2`.`product_cost` AS `product_cost`,
        `s2`.`total_products_sales` AS `total_products_sales`,
        `s2`.`total_products_costs` AS `total_products_costs`,
        (`s2`.`total_products_sales` - `s2`.`total_products_costs`) AS `total_products_profit`
    FROM
        (SELECT 
            `s1`.`product_id` AS `product_id`,
                `s1`.`product_name` AS `product_name`,
                `s1`.`total_sales_perunit` AS `total_sales_perunit`,
                `s1`.`product_price` AS `product_price`,
                `s1`.`product_cost` AS `product_cost`,
                (`s1`.`total_sales_perunit` * `s1`.`product_price`) AS `total_products_sales`,
                (`s1`.`total_sales_perunit` * `s1`.`product_cost`) AS `total_products_costs`
        FROM
            (SELECT 
            `p`.`product_id` AS `product_id`,
                `p`.`product_name` AS `product_name`,
                SUM(`o`.`quantity`) AS `total_sales_perunit`,
                `p`.`product_price` AS `product_price`,
                `i`.`product_cost` AS `product_cost`
        FROM
            ((`produts` `p`
        JOIN `orders` `o` ON ((`p`.`product_id` = `o`.`product_id`)))
        JOIN `invintory` `i` ON ((`p`.`product_id` = `i`.`product_id`)))
        GROUP BY `p`.`product_id`
        ORDER BY `p`.`product_id`) `s1`) `s2`