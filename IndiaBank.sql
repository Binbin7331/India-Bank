--Check for NULL value
SELECT
SUM(CASE WHEN TransactionID is NULL THEN 1 else 0 end) null_transId,
SUM(CASE WHEN CustomerID is NULL THEN 1 else 0 end) null_CustId,
SUM(CASE WHEN CustomerDOB is NULL THEN 1 else 0 end) null_CustDOB,
SUM(CASE WHEN age is NULL THEN 1 else 0 end) null_age,
SUM(CASE WHEN CustGender is NULL THEN 1 else 0 end) null_gender,
SUM(CASE WHEN CustLocation is NULL THEN 1 else 0 end) null_location,
SUM(CASE WHEN CustAccountBalance is NULL THEN 1 else 0 end) null_cab,
SUM(CASE WHEN TransactionDate is NULL THEN 1 else 0 end) null_transdate,
SUM(CASE WHEN TransactionTime is NULL THEN 1 else 0 end) null_transTime,
SUM(CASE WHEN TransactionAmount is NULL THEN 1 else 0 end) null_transAmount

FROM IndiaBank..bank_transactions$
WHERE CustGender is null

--Remove null values
DELETE FROM IndiaBank..bank_transactions$
WHERE CustomerDOB is null or CustGender is null

--Check for duplicated ID
SELECT 
TransactionID,
Count(TransactionID) as total_trans
FROM IndiaBank..bank_transactions$
GROUP BY TransactionID
ORDER BY total_trans DESC

--The age that below 0 means the parents make a transaction for them
SELECT
age
FROM IndiaBank..bank_transactions$
where age < 0


SELECT 
*
FROM IndiaBank..bank_transactions$

-- Find the second lasted date that the customers make a transaction
CREATE VIEW second_date as 
SELECT
CustomerID,
MAX(transactionDate) as second_lasted_date
FROM IndiaBank..bank_transactions$ as bt1
WHERE TransactionDate < (SELECT MAX(transactionDate) FROM IndiaBank..bank_transactions$ as bt2 WHERE bt1.CustomerID = bt2.CustomerID)
GROUP BY CustomerID;
--ORDER BY CustomerID;


SELECT
MAX(TransactionDate)
FROM IndiaBank..bank_transactions$



-- Define rfm score
WITH rfm_customer as 
(
SELECT
CustomerID,
DATEDIFF(day,MAX(transactionDate),'2016/10/31') as recency,
count(CustomerID) as frequency,
ROUND(SUM(TransactionAmount),2) as monetary
FROM IndiaBank..bank_transactions$
--LEFT JOIN second_date sd
--on bt.CustomerID = sd.CustomerID
GROUP BY CustomerID)
--ORDER BY total_transaction DESC)
SELECT 
CustomerID,
NTILE(4) OVER (ORDER BY recency) as recency_quartile,
NTILE(4) OVER (ORDER BY frequency) as frequency_quartile,
NTILE(4) OVER (ORDER BY monetary) as monetary_quartile
FROM rfm_customer;

WITH qt_rfm as(
SELECT 
customerID,
NTILE(4) OVER (ORDER BY recency) as recency_quartile,
NTILE(4) OVER (ORDER BY frequency) as frequency_quartile,
NTILE(4) OVER (ORDER BY monetary) as monetary_quartile
FROM rfm_customer)
SELECT
customerId,
recency_quartile,
frequency_quartile,
monetary_quartile,
CONCAT(recency_quartile,frequency_quartile,monetary_quartile) as rfm_score


group by customerId,recency_quartile,frequency_quartile,monetary_quartile

--CREATE VIEW customer_segment as
SELECT
CustomerId,
rfm_score,
CASE 
WHEN rfm_score in(144,143,134) THEN 'Loyal Customer'
WHEN rfm_score in(142,132,133,233,234,243,244) THEN 'Need Attention'
WHEN rfm_score in(141,131,231,232,241,242) THEN 'Small Basket'
WHEN rfm_score in(124,123,113,114,213,214,414,424) THEN 'Long Time Big buy'
WHEN rfm_score in(121,122,112,113) THEN 'Promising' 
WHEN rfm_score in(111,211,212,221,222) THEN 'New Customer'
WHEN rfm_score in(223,224,243,244) THEN 'Potential Royalist'
WHEN rfm_score in(314,313,324,323,341,331,343,333,334,344) THEN 'At Risk'
WHEN rfm_score in(312,311,321,323,332,342,322) THEN 'Hibernating'
WHEN rfm_score in(424,423,421,422,441,442,431,432,443,433,444,434) THEN 'About to Sleep'
WHEN rfm_score in(411,412,413,414) THEN 'Lost'
END as customer_segment
FROM qt_rfm
ORDER BY customerId


SELECT
bt.*,
cs.customer_segment

FROM IndiaBank..bank_transactions$ bt
JOIN customer_segment cs
on bt.customerID = cs.customerID


SELECT
CustGender,
AVG(TransactionAmount) as average_transaction,
SUM(TransactionAmount) as total_transaction,
MAX(TransactionAmount) as highest_transaction,
MIN(TransactionAmount) as lowest_transaction,
STDEV(TransactionAmount)
--PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TransactionAmount) OVER (PARTITION BY CustGender)
FROM IndiaBank..bank_transactions$
GROUP BY CustGender


SELECT
TOP 10
CustLocation,
AVG(TransactionAmount) as average_transaction,
SUM(TransactionAmount) as total_transaction,
MAX(TransactionAmount) as max_transaction,
MIN(TransactionAmount),
STDEV(TransactionAmount)
FROM IndiaBank..bank_transactions$
GROUP BY CustLocation
ORDER BY total_transaction DESC



WITH customer_numbers as (
SELECT
custlocation,
COUNT(DISTINCT(CustomerID)) as total_customer
FROM IndiaBank..bank_transactions$
GROUP BY CustLocation
)
SELECT
ib.CustLocation,
AVG(ib.CustAccountBalance) as average_balance,
MIN(ib.CustAccountBalance) as minimum_balance,
MAX(ib.CustAccountBalance) as maximum_balance,
SUM(ib.CustAccountBalance) as total_balance_amount 

FROM IndiaBank..bank_transactions$ ib
JOIN customer_numbers cn
ON ib.CustLocation = cn.CustLocation
WHERE cn.total_customer > 10000
GROUP BY ib.Custlocation
ORDER BY average_balance DESC