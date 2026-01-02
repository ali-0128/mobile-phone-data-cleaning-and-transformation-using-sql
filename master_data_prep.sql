-- I. SETUP & INITIAL DATA AUDIT

-- Check for data quality issues (Duplicates, Missing Values)
select
    [brand_name],
    [model_name],
    count(*) as duplicate_count
from phones
group by 
    [brand_name],
    [model_name]
having count(*) > 1;

-- DELETE TRUE DUPLICATES
with duplicatecte as (
    select*,
        row_number() over (partition by brand_name, model_name order by [row_number] ) as row_num
    from phones)
delete from duplicatecte
where row_num > 1;

-- Calculate the count of missing values for all columns
select 
	count(*) as total_rows,	
	sum(case when [row_number] is null then 1 else 0 end) as 'row_number',
	sum(case when brand_name is null then 1 else 0 end) as 'brand_name',
	sum(case when model_name is null then 1 else 0 end) as 'model_name',
	sum(case when os is null then 1 else 0 end) as 'os',
	sum(case when popularity is null then 1 else 0 end) as 'popularity',
	sum(case when best_price is null then 1 else 0 end) as 'best_price',
	sum(case when lowest_price is null then 1 else 0 end) as 'lowest_price',
	sum(case when highest_price is null then 1 else 0 end) as 'highest_price',
	sum(case when sellers_amount is null then 1 else 0 end) as 'sellers_amount',
	sum(case when screen_size is null then 1 else 0 end) as 'screen_size',
	sum(case when memory_size is null then 1 else 0 end) as 'memory_size',
	sum(case when battery_size is null then 1 else 0 end) as 'battery_size',
	sum(case when release_date is null then 1 else 0 end) as 'release_date'
from phones;


-- II. DATA CLEANING & IMPUTATION

-- 1. Handle Categorical Missing Data (OS)
update phones
	set os = 'Unknown'
where os is null;


-- 2. Handle Numeric Missing Data (Imputation by Median)
-- Calculate the mean and median to identify the impact of outliers on price and memory data.
select distinct
    avg([lowest_price]) over () as mean_lowest_price,
	percentile_cont(0.5) within group (order by [lowest_price]) over () as median_lowest_price,
    avg([highest_price]) over () as mean_highest_price,
	percentile_cont(0.5) within group (order by [highest_price]) over () as median_highest_price,
    avg([memory_size]) over () as mean_memory_size,
    percentile_cont(0.5) within group (order by [memory_size]) over () as median_memory_size	
from
    phones;

-- Declare variables to store median values for efficient imputation.
declare @medlp decimal(18, 2);
declare @medhp decimal(18, 2);
declare @medms decimal(18, 2);

-- Calculate and store median values once.
select distinct
    @medlp = percentile_cont(0.5) within group (order by lowest_price) over (),
    @medhp = percentile_cont(0.5) within group (order by highest_price) over (),
    @medms = percentile_cont(0.5) within group (order by [memory_size]) over ()
from phones;

-- Apply median imputation to price and memory columns.
update phones set lowest_price = @medlp where lowest_price is null;
update phones set highest_price = @medhp where highest_price is null;
update phones set [memory_size] = @medms where [memory_size] is null;


-- 3. Data Deletion (Removing rows with crucial missing values)
delete phones where screen_size is null;
delete phones where battery_size is null;


-- 4. Date Formatting
-- Convert 'MM-YYYY' string to proper DATE format by assuming day '01'.
update phones
set release_date = convert(date, '01-' + release_date, 105)
where release_date is not null 
    and isdate('01-' + release_date) = 1;


-- III. FEATURE ENGINEERING & PERSISTENCE

-- 1. Schema Alteration
-- Add new columns to the main table to store extracted features permanently.
alter table phones add ram_size varchar(10);
alter table phones add phone_color varchar(50);


-- 2. Extract Features and Update
-- Use a CTE to calculate new features from the raw model name, then JOIN and update the main table.
with featureextraction as (
    select
        model_name, 
        
		case
            when model_name like '% 1/8GB%' or model_name like '% 1/16GB%' then '1GB'
            when model_name like '% 2/16GB%' or model_name like '% 2/32GB%' then '2GB'
            when model_name like '% 3/32GB%' or model_name like '% 3/64GB%' or model_name like '% 3/128GB%' then '3GB'
            when model_name like '% 4/32GB%' or model_name like '% 4/64GB%' or model_name like '% 4/128GB%' then '4GB'
            when model_name like '% 6/64GB%' or model_name like '% 6/128GB%' then '6GB'
            when model_name like '% 8/128GB%' or model_name like '% 8/256GB%' then '8GB'
            when model_name like '% 12/256GB%' then '12GB'
        
            when model_name like '% 16GB%' or model_name like '%(16GB%' then '16GB'
            when model_name like '% 12GB%' or model_name like '%(12GB%' then '12GB'
            when model_name like '% 8GB%' or model_name like '%(8GB%' or model_name like '% 8G %' then '8GB'
            when model_name like '% 6GB%' or model_name like '%(6GB%' then '6GB'
            when model_name like '% 4GB%' or model_name like '%(4GB%' or model_name like '% 4G %' then '4GB'
            when model_name like '% 3GB%' or model_name like '%(3GB%' then '3GB'
            when model_name like '% 2GB%' or model_name like '%(2GB%' then '2GB'
            when model_name like '% 1GB%' or model_name like '%(1GB%' then '1GB'
            else null 
        end as calculated_ram_size,

        case
            when model_name like '% black%' then 'Black'
            when model_name like '% white%' then 'White'
            when model_name like '% gold%' then 'Gold'
            when model_name like '% blue%' then 'Blue'
            when model_name like '% red%' then 'Red'
            when model_name like '% green%' then 'Green'
            when model_name like '% pink%' then 'Pink'
            when model_name like '% silver%' then 'Silver'
            when model_name like '% gray%' then 'Gray'
            when model_name like '% violet%' then 'Violet'
            when model_name like '% yellow%' then 'Yellow'
            else 'Unknown/Default'
        end as calculated_phone_color
    from phones
)
update p
set
    p.ram_size = fe.calculated_ram_size,
    p.phone_color = fe.calculated_phone_color
from phones as p
join featureextraction as fe on p.model_name = fe.model_name;

-- Final check of cleaned data (for demonstration purposes)
select * from phones;