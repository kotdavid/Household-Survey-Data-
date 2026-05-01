
-------- Household Survey Data -------

ALTER DATABASE postgres RENAME TO "HH Food and Nutrition";

--- intialize the columns 
CREATE TABLE IF NOT EXISTS HH_Food_and_Nutrition (
household_id             bigserial PRIMARY KEY,
governorate   char(20) NOT NULL,
Displacement_status     integer,
Sex_of_head_of_household  integer,
Number_of_females_household_members      numeric,
Number_of_males_household_members    integer,
Household_size  integer,
Dietary_diversity_core integer,
Monthly_Expenditure_on_Food_LCU integer,
Total_Monthly_Expenditure_LCU integer,
Household_debt_LCU integer,
Marital_status numeric 
);

select * from hh_food_and_nutrition hfan;


-- 1. Find the duplicates records of governorate where  total_monthly_expenditure_lcu is greater than 960
select * from hh_food_and_nutrition hfan; -- dataset
select hfan.household_id , hfan.governorate 
from HH_Food_and_Nutrition hfan
where hfan.total_monthly_expenditure_lcu >= 960;

--- 2. Retrieve the second highest Total_Monthly_Expenditure_LCU from the  table
select * from hh_food_and_nutrition hfan; -- dataset
select MAX(Total_Monthly_Expenditure_LCU) as secondHighest_Total_Monthly_Expenditure_LCU
from hh_food_and_nutrition hfan 
where Total_Monthly_Expenditure_LCU < (
select 
max(Total_Monthly_Expenditure_LCU)
from hh_food_and_nutrition hfan);

-- 3. Find governorate with IDP dispalcement status (1= host community, 2=IDP)
select * from hh_food_and_nutrition hfan; -- dataset
select governorate 
from hh_food_and_nutrition hfan 
where hfan.displacement_status =2;

-- 4. Aggregate Household_debt_LCU and total_monthly_expenditure_lcu per household_id
select * from hh_food_and_nutrition hfan; -- dataset
select household_id, 
sum(Household_debt_LCU + total_monthly_expenditure_lcu) as hh_debt_total_monthly_expenditure
from hh_food_and_nutrition
group by household_id;

-- 5. Get the top 10 highest-total monthly expenditure by household_id
select * from hh_food_and_nutrition hfan; -- dataset
select household_id, total_monthly_expenditure_lcu
from hh_food_and_nutrition
group by household_id  
order by total_monthly_expenditure_lcu desc
limit 10;
-- or 
fetch first 5 rows with ties; -- multiple household_id that share the same total_monthly_expenditure_lcu, hence use ties:


-- 6. Calculate the average household debt per marital status 
select * from hh_food_and_nutrition hfan; -- dataset
select marital_status,  
AVG(Household_debt_LCU) as avg_Household_debt_LCU
from hh_food_and_nutrition 
group by marital_status;

-- 7. Get the total_monthly_expenditure_lcu and Monthly_Expenditure_on_Food_LCU per governorate
select * from hh_food_and_nutrition hfan; -- dataset
select governorate,
sum(total_monthly_expenditure_lcu) as new_totalMonthlyExpenditure,
count(*) as New_Monthly_Expenditure_on_Food_LCU
from hh_food_and_nutrition 
group by governorate;

-- 8. Count how many household have > 5 member of the households.
select * from hh_food_and_nutrition hfan; -- dataset
select count(*) as MoreThan5Members  -- outer query
from (select Household_size 		-- inner query
from hh_food_and_nutrition
group by Household_size
having count(*) > 5
) as subquery;


-- 9. Retrieve governorate with  monthly expenditure above the average
select * from hh_food_and_nutrition hfan; -- dataset
select * 
from hh_food_and_nutrition hfan 
where monthly_expenditure_on_food_lcu > 		-- outer queery
(select 										-- inner query
AVG(monthly_expenditure_on_food_lcu) 
from hh_food_and_nutrition);

-- 10. Rank household_debt_lcu by household_id within each governorate.
select * from hh_food_and_nutrition hfan; -- dataset
select household_id, governorate, household_debt_lcu, 
dense_rank() 		-- no gaps in ranking
over(partition by governorate 
order by household_debt_lcu desc) as hh_debt_ranking 
from hh_food_and_nutrition hfan;

-- 11. Identify the lowest and highest household_debt_lcu by marital status (1=married, 2=single, 3=divorced, 4=seperated)
select * from hh_food_and_nutrition hfan; -- dataset
select hfan.marital_status , 
MIN(household_debt_lcu) as lowest_debt,
MAX(household_debt_lcu) as highest_debts
from hh_food_and_nutrition hfan 
group by hfan.marital_status;

-- 12. Show governorate distribution as % of total monthly expenditure
select * from hh_food_and_nutrition hfan; -- dataset
WITH total_monthly_expenditure_lcu AS (
SELECT
SUM(total_monthly_expenditure_lcu + household_debt_lcu) AS total_spendings
FROM hh_food_and_nutrition)					--- Calculates one single value as total spending across all households
SELECT
household_id,			--- group data by households, Calculates total expenses per household
SUM(total_monthly_expenditure_lcu + household_debt_lcu) AS expenses,
SUM(total_monthly_expenditure_lcu + household_debt_lcu) * 100.0 / total_spendings AS spendings_pct
FROM hh_food_and_nutrition
CROSS JOIN total_monthly_expenditure_lcu		-- attaches that value to every row
GROUP BY household_id, total_spendings;

-- 13. Identify households with total_monthly_expenditure_lcu below the 10th percentile
select * from hh_food_and_nutrition hfan;
with cte as (	--- cte help calculate total expenditure per household, then resuse result to calculate percentile and filter households
select household_id, 
sum(total_monthly_expenditure_lcu) as total_hh_expenditure
from hh_food_and_nutrition hfan 
group by hfan.household_id)
select household_id, total_hh_expenditure
from cte 
where total_hh_expenditure < 
(select percentile_cont(0.1) 
within group 
(order by total_hh_expenditure) 
from cte);


-- 14. Detect households whose debt amount is higher than their historical 90th percentile.
select * from hh_food_and_nutrition hfan;
WITH ranked_monthly_expenditure_on_food_lcu AS (
SELECT household_id, governorate, household_debt_lcu,
NTILE(10) 			-- Divides all rows into 10 equal groups called decile
OVER (ORDER BY household_debt_lcu) AS decile
FROM hh_food_and_nutrition hfan)
SELECT *
FROM ranked_monthly_expenditure_on_food_lcu
WHERE decile = 10;


------------------------ THE END ---------------------------




















