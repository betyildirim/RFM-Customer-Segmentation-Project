/*
PROJECT: Customer Segmentation with RFM Analysis
AUTHOR: Fatma Betul Yildirim
DATE: 29.12.2025
*/

-- =======================================================
-- 1. TABLE CREATION
-- =======================================================
-- We initially create the table with VARCHAR (text) for all columns 
-- to avoid import errors (e.g., comma vs. dot decimals).
drop table if exists retail;

create table retail (
    Invoice varchar(255),
    StockCode varchar(255),
    description varchar(255),
    Quantity varchar(255),
    InvoiceDate varchar(255),
    Price varchar(255),
    Customer_ID varchar(255),
    Country varchar(255)
);

-- NOTE: Data import was handled via pgAdmin Import Tool.
-- Settings used: Header=Yes, Delimiter=; (Semicolon), Encoding=ISO-8859-1

-- =======================================================
-- 2. DATA TYPE CASTING
-- =======================================================
-- Converting string data into proper numeric and timestamp formats for analysis.

-- Convert Price: Replace comma with dot, then cast to NUMERIC.
alter table retail 
alter COLUMN Price type numeric 
using REPLACE(Price, ',', '.')::numeric;

-- Convert Quantity: Cast to INTEGER.
alter table retail 
alter COLUMN Quantity type integer 
using Quantity::integer;

-- Convert InvoiceDate: Cast to TIMESTAMP using the correct format.
alter table retail 
alter COLUMN InvoiceDate type timestamp 
using TO_TIMESTAMP(InvoiceDate, 'DD.MM.YYYY HH24:MI');

-- =======================================================
-- 3. DATA CLEANING
-- =======================================================
-- Removing records that cannot be used for customer segmentation.

/* -- INSPECTION STEP (CONTROL STEP):
-- Before deleting, we checked the counts of invalid records:
SELECT 
    COUNT(*) FILTER (WHERE Customer_ID IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE Invoice LIKE 'C%') AS cancelled_invoices
FROM retail;
-- Result: ~135k missing IDs and ~9k cancellations found.

*/
-- Remove records with no Customer ID (Anonymous transactions).
delete from retail where Customer_ID is null;

-- Remove Cancelled transactions (Invoices starting with 'C').
delete from retail where Invoice like 'C%';

-- =======================================================
-- 4. RFM METRICS CALCULATION
-- =======================================================
/* Step 1: Determine the analysis date.
(Max Date in Data: 2011-12-09 -> Analysis Date: 2011-12-11)

Step 2: Calculate metrics.
- Recency: Analysis Date - Last Purchase Date
- Frequency: Count of unique invoices
- Monetary: Sum of (Quantity * Price)
*/

select 
Customer_ID,
('2011-12-11'::date - max(InvoiceDate)::date) as Recency,
count(distinct Invoice) as Frequency,
sum(Quantity * Price) as Monetary
from retail
group by Customer_ID
order by Monetary desc;

-- =======================================================
-- 5. CREATING RFM METRICS TABLE
-- =======================================================
-- We are creating a permanent table 'rfm_metrics' to store the calculated results.
-- This makes the subsequent scoring (1-5 points) much faster and easier.

drop table if exists rfm_metrics;

create table rfm_metrics as
select Customer_ID,
    ('2011-12-11'::date - max(InvoiceDate)::date) as Recency,
    count(distinct Invoice) as Frequency,
    sum(Quantity * Price) as Monetary
from retail
group by Customer_ID;


/*
--------------------------------------------------------------------------
 STEP 6: CALCULATION OF RFM SCORES
--------------------------------------------------------------------------
 Description:
    In this step, raw metrics are converted into scores ranging from 1 to 5 
    using the NTILE window function. This standardization allows for 
    segmentation based on relative performance.

 Logic:
    1. Recency:   Inverse relationship. Lower 'Recency' indicates a more 
                  recent active customer. Therefore, smallest values get 5.
    2. Frequency: Direct relationship. Higher count gets 5.
    3. Monetary:  Direct relationship. Higher value gets 5.
*/

drop table if exists rfm_scores;

create table rfm_scores as
select 
    Customer_ID,
    Recency,
    Frequency,
    Monetary,
    -- Recency Scoring: 5 = Most Recent, 1 = Least Recent
    ntile(5) over (order by Recency desc) as Recency_Score,
    
    -- Frequency Scoring: 5 = Most Frequent, 1 = Least Frequent
    ntile(5) over (order by Frequency asc) as Frequency_Score,
    
    -- Monetary Scoring: 5 = Highest Spender, 1 = Lowest Spender
    ntile(5) over (order by Monetary asc) as Monetary_Score
from rfm_metrics;

-- Concatenating scores to create the final RFM Score (e.g., '555', '121')
-- This string format facilitates easier mapping in the next step.
alter table rfm_scores add COLUMN RFM_SCORE varchar(3);

update rfm_scores 
set RFM_SCORE = CAST(Recency_Score as varchar) || 
                CAST(Frequency_Score as varchar) || 
                CAST(Monetary_Score as varchar);

-- Validation Check
select * from rfm_scores limit 10;


/*
--------------------------------------------------------------------------
 STEP 7: CUSTOMER SEGMENTATION (MAPPING)
--------------------------------------------------------------------------
 Description:
    Segments are created based on the combination of Recency (R) and 
    Frequency (F) scores. 

 Methodology:
    Standard RFM mapping logic is applied.
    CRITICAL FIX: 'Cant Loose' segment is defined BEFORE 'At Risk' to 
    prevent logic overlapping.
*/

alter table rfm_scores add COLUMN Segment varchar(50);

update rfm_scores
set Segment = case 
    -- 1. CHAMPIONS (Bought recently, buys often)
    when Recency_Score = 5 and Frequency_Score in (4, 5) then 'Champions'
    
    -- 2. LOYAL CUSTOMERS (Buys regularly. Responsive to promotions)
    when Recency_Score in (3, 4) and Frequency_Score in (4, 5) then 'Loyal Customers'
    
    -- 3. POTENTIAL LOYALISTS (Recent customers, but spent average amount)
    when Recency_Score in (4, 5) and Frequency_Score in (2, 3) then 'Potential Loyalists'
    
    -- 4. NEW CUSTOMERS (Bought most recently, but not often)
    when Recency_Score = 5 and Frequency_Score = 1 then 'New Customers'
    
    -- 5. PROMISING (Recent shoppers, but haven't returned much)
    when Recency_Score = 4 and Frequency_Score = 1 then 'Promising'
    
    -- 6. NEED ATTENTION (Above average recency, frequency and monetary)
    when Recency_Score = 3 and Frequency_Score = 3 then 'Need Attention'
    
    -- 7. ABOUT TO SLEEP (Below average recency, frequency and monetary)
    when Recency_Score = 3 and Frequency_Score in (1, 2) then 'About to Sleep'
    
    -- 8. CAN'T LOOSE THEM (VIPs at risk) - MOVED UP!
    -- Must be checked BEFORE 'At Risk' because (R=1, F=4,5) is a subset of At Risk logic.
    when Recency_Score = 1 and Frequency_Score in (4, 5) then 'Cant Loose'
    
    -- 9. AT RISK (Others)
    when Recency_Score in (1, 2) and Frequency_Score in (3, 4, 5) then 'At Risk'
    
    -- 10. HIBERNATING (Low recency, low frequency)
    when Recency_Score in (1, 2) and Frequency_Score in (1, 2) then 'Hibernating'
    
    else 'Other'
end;

/* --------------------------------------------------------------------------
 FINAL ANALYSIS: SEGMENT OVERVIEW
--------------------------------------------------------------------------
 Check the distribution of customers across segments.
*/
select
    Segment, 
    COUNT(*) as Total_Customers, 
    ROUND(AVG(Recency), 0) as Avg_Recency_Days,
    ROUND(AVG(Frequency), 1) as Avg_Frequency,
    ROUND(AVG(Monetary), 0) as Avg_Monetary
from rfm_scores
group by Segment
order by Total_Customers desc;

/*
--------------------------------------------------------------------------
 STEP 8: ACTIONABLE INSIGHTS (TARGET LISTS)
--------------------------------------------------------------------------
 Description:
    The final step is to extract actionable lists for the marketing team.
    Instead of giving them the whole database, we provide focused lists
    for specific campaigns.

 Scenario: 
    We want to run a "Win-Back" campaign for high-value customers 
    who are at risk of churning.
*/

-- Query 1: "Champions" - To offer early access or rewards
select 
    Customer_ID,
    Recency,
    Frequency,
    Monetary,
    'High Value Reward' as Suggested_Action
from rfm_scores
where Segment = 'Champions'
order by Monetary desc
limit 10;

-- Query 2: "Can't Loose" - Immediate intervention required
select 
    Customer_ID,
    Recency,
    Frequency,
    Monetary,
    'Win-Back Campaign' as Suggested_Action
from rfm_scores
where Segment = 'Cant Loose'
order by Recency desc;
