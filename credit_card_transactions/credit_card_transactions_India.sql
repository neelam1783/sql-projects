/* SQL porfolio project.

download credit card transactions dataset from below link :
https://www.kaggle.com/datasets/thedevastator/analyzing-credit-card-spending-habits-in-india
import the dataset in mysql with table name : credit_card

while importing make sure to change the data types of columns.

write the queries to explore the dataset and put your findings 

solve below questions

1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

2- write a query to print highest spend month and amount spent in that month for each card type
3- write a query to print the transaction details(all columns from the table) for each card type when
it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

4- write a query to find city which had lowest percentage spend for gold card type

5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

6- write a query to find percentage contribution of spends by females for each expense type

7- which card and expense type combination saw highest month over month growth in Jan-2014
9- during weekends which city has highest total spend to total no of transcations ratio  

*/

create database sql_portfolio;
use sql_portfolio;

create table credit_card(
serial_no int,
city varchar(45),
issued_date	Date,
card_type varchar(30),
exp_type varchar(30),
gender varchar(5),
amount int
);
truncate credit_card;


LOAD DATA INFILE 'C:/sql_portfolio_project/credit_card_transactions_India.csv' 
INTO TABLE credit_card 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
desc credit_card;

/*1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends */
with cte1 as 
(select city,sum(amount) as total_spend from credit_card
group by city order by total_spend),
cte2 as
(select sum(amount) as total_amount from credit_card)

select c.*,(c.total_spend *1.0/total_amount*100) as 
percentage_contribution from cte1 c inner join cte2 on 1=1 order by total_spend desc limit 5;

/*2 - write a query to print highest spend month and amount spent in that month for each card type */



with cte as(
select card_type,monthname(issued_date) as month_name,sum(amount) monthly_total,
rank() over(partition by card_type order by sum(amount) desc) as rnk
 
from credit_card
group by 1,2) 
select card_type,month_name,monthly_total from cte where rnk=1

/* 3. write a query to print the transaction details(all columns from the table) for each card type when
it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)*/;

with cte as 
(select *,sum(amount) over(partition by card_type order by issued_date,serial_no) as total_sum from credit_card),
cte2 as
(select *,rank() over(partition by card_type order by total_sum) as rn from cte where total_sum >1000000)
select * from cte2 where rn=1


/*4- write a query to find city which had lowest percentage spend for gold card type */;
with cte as (
select  city,card_type,sum(amount) as amount
,sum(case when card_type='Gold' then amount end) as gold_amount
from credit_card
group by city,card_type)
select 
city,sum(gold_amount)*1.0/sum(amount) as gold_ratio
from cte
group by city
having count(gold_amount) > 0 and sum(gold_amount)>0
order by gold_ratio limit 1;





/*5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)*/
with cte as (
select city,exp_type, sum(amount) as total_amount from credit_card
group by city,exp_type),

cte2 as(
 select *
,rank() over(partition by city order by total_amount desc) rn_desc
,rank() over(partition by city order by total_amount asc) rn_asc
from cte

 )
select
city , min(case when rn_asc=1 then exp_type end) as lowest_exp_type
, min(case when rn_desc=1 then exp_type end) as highest_exp_type from cte2 group by city;

/* 6- write a query to find percentage contribution of spends by females for each expense type */

with cte as(
select exp_type,sum(amount) as total_amount,sum(case when gender ='F' then amount end) as femal_Contri 
from credit_card  group by exp_type )

select * ,round((femal_Contri *1.0 / total_amount *100),2) as female_contri_percentage from cte

/* 7. which card and expense type combination saw highest month over month growth in Jan-2014 */ ;

with cte as (select card_type, exp_type ,extract(year from issued_date) as yt,extract(month from issued_date) as mt ,sum(amount) as total_spend
from credit_card 
group by 1,2,3,4 order by 1,2,3,4),
cte2 as(
select *,lag(total_spend) over(partition by card_type,exp_type) as pre_spend from cte)

select *,(total_spend-pre_spend)as growth
 from cte2 
 where 
 pre_spend is not null and yt=2014 and mt=1 
 order by growth desc limit 1 ;

/*8 during weekends which city has highest total spend to total no of transcations ratio */


select city,sum(amount)*1.0/count(city) as total_spend from credit_card 
where weekday(issued_date) in(5,6) 
group by 1 
order by total_spend desc 
limit 1;

/* 9) which city took least number of days to reach its 500th transaction after the first transaction in that city */


 
 
 
 with cte as(
select * ,row_number() over(partition by city order by issued_date) as rnk from credit_card )


select city,datediff(max(issued_date),min(issued_date)) as no_days 
from cte 
where rnk=1 or rnk=500 
group by city 
having count(city) = 2
 order by no_days limit 1 
 ;

