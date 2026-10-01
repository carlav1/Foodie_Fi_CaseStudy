-- Link: https://8weeksqlchallenge.com/case-study-3/

use schema TIL_PLAYGROUND.CS3_FOODIE_FI

select * 
from plans;

select * 
from subscriptions; 

--customer journey

select 
customer_id, 
plan_name,
start_date
from subscriptions as a 
inner join plans as b 
on a.plan_id = b.plan_id
order by customer_id ASC, start_date ASC;

--Data Analysis Questions 

--Question 1 How many customers has Foodie-Fi ever had?

select distinct count(customer_id) as total_customers
from subscriptions; 

--Question 2 What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value?

select
month(start_date) as month_number,
count(customer_id)
from subscriptions as a 
inner join plans as b 
on a.plan_id = b.plan_id
where plan_name = 'trial'
group by month_number
order by month_number; 

--Question 3 What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

select
plan_name,
count(*) as event_count
from subscriptions as a 
inner join plans as b 
on a.plan_id = b.plan_id
where start_date >= '2021-01-01'::date
group by plan_name
order by event_count DESC;

select
max(start_date)
from subscriptions;

--Question 4 What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

select
round(count(distinct customer_id), 1) as total_customer_churn,
round(count(customer_id)/ (select count(distinct customer_id) from subscriptions) , 1) * 100 as customer_percent_churn 
from subscriptions as a 
inner join plans as b 
on a.plan_id = b.plan_id
where plan_name = 'churn';

--Question 5 How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

with churn_table as 
(
select
customer_id,
plan_name,
row_number() over (partition by customer_id order by start_date ASC) as row_count
from subscriptions as a 
inner join plans as b 
on a.plan_id = b.plan_id
)
 
select distinct count(customer_id) as total_churn_cust_after_freetrial,
round(count( distinct customer_id)/ (select count( distinct customer_id) from subscriptions)  * 100, 0) as customer_percent_churn 
from churn_table
where row_count = 2 and plan_name = 'churn';

--Question 6 What is the number and percentage of customer plans after their initial free trial?

with churn_table as 
(
select
customer_id,
plan_name,
row_number() over (partition by customer_id order by start_date ASC) as row_count
from subscriptions as a 
inner join plans as b 
on a.plan_id = b.plan_id
)
 
select distinct count(customer_id) as customer_count,
round(count(customer_id)/ (select count( distinct customer_id) from churn_table)  * 100, 0) as customer_percent,
plan_name
from churn_table
where row_count = 2 and plan_name <> 'churn'
group by plan_name;

--Question 7 What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
with plan_table as (
select
customer_id,
plan_name,
start_date,
row_number() over (partition by customer_id order by start_date DESC) as row_count
from subscriptions as a 
inner join plans as b 
on a.plan_id = b.plan_id 
where start_date <= '2020-12-31'::date  
)
 
select distinct count(customer_id) as customer_count,
count(customer_id)/ (select count(distinct customer_id) from plan_table)  * 100 as customer_percent,
plan_name
from plan_table
where row_count =1
group by plan_name
order by customer_count DESC;

--Question 8 How many customers have upgraded to an annual plan in 2020?
with plan_table as (
select
customer_id,
plan_name,
start_date,
row_number() over (partition by customer_id order by start_date ASC) as row_count
from subscriptions as a 
inner join plans as b 
on a.plan_id = b.plan_id 
where year(start_date) = 2020

)

select count(distinct customer_id) as annual_plan_cust
from plan_table 
where plan_name = 'pro annual'; 

--Question 9 How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

with start_table as (
select
customer_id,
start_date,
plan_id
from subscriptions 
where plan_id =0

),

end_table as (
select
customer_id,
start_date as end_date,
plan_id
from subscriptions 
where plan_id =3
)

select
AVG(datediff(day, a.start_date, b.end_date)) as avg_days
from start_table as a
inner join end_table as b
on a.customer_id = b.customer_id;


--Question 10 Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

with start_table as (
select
customer_id,
start_date,
plan_id
from subscriptions 
where plan_id =0

),

//select min(start_date) from start_table; -- finding min date

end_table as (
select
customer_id,
start_date as end_date,
plan_id
from subscriptions 
where plan_id =3
)

//select max(end_date) from end_table; -- finding max date

select
(CASE
when datediff(day, a.start_date, b.end_date) <= 30 then '0-30 days'
when datediff(day, a.start_date, b.end_date) <= 60 then '31-60 days'
when datediff(day, a.start_date, b.end_date) <= 90 then '61-90 days'
when datediff(day, a.start_date, b.end_date) <= 120 then '91-120 days'
when datediff(day, a.start_date, b.end_date) <= 150 then '121-150 days'
when datediff(day, a.start_date, b.end_date) <= 180 then '151-180 days'
when datediff(day, a.start_date, b.end_date) <= 210 then '181-210 days'
when datediff(day, a.start_date, b.end_date) <= 240 then '211-240 days'
when datediff(day, a.start_date, b.end_date) <= 270 then '241-270 days'
when datediff(day, a.start_date, b.end_date) <= 300 then '271-300 days'
when datediff(day, a.start_date, b.end_date) <= 330 then '300-330 days'
when datediff(day, a.start_date, b.end_date) <= 360 then '330-360 days'
END) as bin_days,
count(a.customer_id) as customer_count
from start_table as a
inner join end_table as b
on a.customer_id = b.customer_id
group by bin_days
order by customer_count DESC;

--Question 11 How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
with lag_table as
(
select customer_id, 
plan_name,
lag(plan_name) over (partition by customer_id order by start_date) old_plan,
start_date
from subscriptions as a
inner join plans as b
on a.plan_id = b.plan_id
)
select 
count(customer_id) as customer_count
from lag_table 
where old_plan ='pro monthly' and plan_name = 'basic monthly'
and year(start_date) = 2020;