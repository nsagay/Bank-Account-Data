--- What do these tables look like individually?
SELECT *
FROM   analytics-take-home-test.monzo_borrowing.accounts_sample;

SELECT *
FROM   analytics-take-home-test.monzo_borrowing.monthly_performance;

--- What do these tables look like together?
CREATE VIEW combined_bank AS 
SELECT m.account_id,
       s.credit_score_band_at_origination,
	   s.annual_interest_rate,
       m.DATE,
       m.account_status,
       m.overdraft_balance,
       m.overdraft_limit,
       m.in_financial_difficulties_flag,
       m.total_value_transactions_made
FROM   monthly_performance m
       INNER JOIN accounts_sample s
               ON s.account_id = m.account_id;
-- Look at view --
SELECT * FROM combined_bank;
-- Create a function that determines if the account is overdrawn beyond the limit
DELIMITER $$
CREATE FUNCTION is_overlimit(balance FLOAT, limit FLOAT) 
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE customer_status VARCHAR(20);
    IF limit > balance THEN
        SET customer_status = 'YES';
    ELSEIF (limit = balance)THEN
        SET customer_status = 'MAYBE';
    ELSEIF limit < balance THEN
        SET customer_status = 'NO';
    END IF;
    RETURN (customer_status);
END $$
DELIMITER;

SELECT *, is_overlimit(overdraft_balance,overdraft_limit) AS customer_status 
FROM combined_bank
WHERE customer_status = 'N0';



-- Given the credit band, how more likely are they going to be in their overdraft over time. 
SELECT m.DATE,
       s.credit_score_band_at_origination,
       Sum( m.overdraft_limit - m.overdraft_balance )
FROM   monthly_performance m
       INNER JOIN accounts_sample s
               ON s.account_id = m.account_id
GROUP  BY s.credit_score_band_at_origination,
          m.DATE
ORDER  BY s.credit_score_band_at_origination,
          m.DATE;

-- Count the proportion of different bands in the portfolio. Has that proportion changed
-- With the proportion
SELECT m.DATE,
       s.credit_score_band_at_origination,
       m.in_financial_difficulties_flag,
       Sum( m.overdraft_limit - m.overdraft_balance ) AS difference
FROM   monthly_performance m
       INNER JOIN accounts_sample s
               ON s.account_id = m.account_id
GROUP  BY s.credit_score_band_at_origination,
          m.DATE,
          m.in_financial_difficulties_flag
ORDER  BY s.credit_score_band_at_origination,
          m.DATE;

-- How many people are close or over their overdraft limit? How has this changed#
SELECT s.credit_score_band_at_origination,
       Avg(m.overdraft_balance),
       Avg(m.overdraft_limit),
	   AVG(m.overdraft_limit - m.overdraft_balance),
       Avg(m.total_value_transactions_made)
FROM   monthly_performance m
       INNER JOIN accounts_sample s
               ON s.account_id = m.account_id
GROUP  BY s.credit_score_band_at_origination
ORDER  BY s.credit_score_band_at_origination;

-- What factors would be necessary in understanding the health of a borrowing portfolio?
SELECT s.credit_score_band_at_origination, s.annual_interest_rate
FROM   monthly_performance m
       INNER JOIN accounts_sample s
               ON s.account_id = m.account_id
GROUP  BY s.credit_score_band_at_origination, s.annual_interest_rate
ORDER  BY s.credit_score_band_at_origination, s.annual_interest_rate;
