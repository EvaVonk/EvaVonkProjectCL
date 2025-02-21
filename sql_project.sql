USE financial9_99; -- from now on, the default database schema we use is: financial

-- checking type of relationship
SELECT
    account_id,
    count(trans_id) as amount
FROM trans
GROUP BY account_id
ORDER BY 2 DESC



-- Write a query that prepares a summary of the granted loans in the following dimensions:
-- year, quarter, month,
-- year, quarter,
-- year,
-- total.
-- Display the following information as the result of the summary:

-- total amount of loans,
-- average loan amount,
-- total number of given loans.

SELECT *
FROM financial9_99.loan

SELECT
    extract(YEAR FROM date) as year,
    extract(QUARTER FROM date) as quarter,
    extract(MONTH FROM date) as month,
    sum(amount) as loan_total_amount,
    avg(amount) as loan_avg_amount,
    count(amount) as loan_count_amount

FROM financial9_99.loan
group by year, quarter, month with rollup
order by year, quarter, month;

-- Write a query that ranks accounts according to the following criteria:

-- number of given loans (decreasing),
-- amount of given loans (decreasing),
-- average loan amount,
-- Only fully paid loans are considered.

WITH account_ranking AS (
    SELECT
       account_id,
       sum(amount)   as loan_amount,
       count(amount) as loan_count,
       avg(amount)   as loan_avg
    FROM financial9_99.loan
    WHERE status IN ('A', 'C')
    GROUP BY account_id
)
SELECT
    *,
    DENSE_RANK() OVER (ORDER BY loan_amount DESC) AS rank_loans_amount,
    DENSE_RANK() OVER (ORDER BY loan_count DESC) AS rank_loans_count
FROM account_ranking;

-- Fully paid loans
-- Find out the balance of repaid loans, divided by client gender.

-- Additionally, use a method of your choice to check whether the query is correct.

select count(distinct loan_id),
       sum(amount),
       gender
from loan

join financial9_99.account a on loan.account_id = a.account_id
join financial9_99.disp d on a.account_id = d.account_id
join financial9_99.client c on c.client_id = d.client_id
where status in ('A', 'C')
AND d.type = 'OWNER'
group by gender
order by sum(amount);

-- Client analysis - part 1
-- Modifying the queries from the exercise on repaid loans, answer the following questions:

-- Who has more repaid loans - women or men? - Women
-- What is the average age of the borrower divided by gender?
-- Hints:

-- Save the result of the previously written and then modified query, for example, to a temporary table, and conduct the analysis on it.

WITH gender_rate AS (
    SELECT
        COUNT(DISTINCT loan.loan_id) AS loan_count,
        SUM(loan.amount) AS total_amount,
        c.gender
    FROM loan
    JOIN financial9_99.account a ON loan.account_id = a.account_id
    JOIN financial9_99.disp d ON a.account_id = d.account_id
    JOIN financial9_99.client c ON c.client_id = d.client_id
    WHERE loan.status IN ('A', 'C')
      AND d.type = 'OWNER'
    GROUP BY c.gender
),
avg_age AS (
    SELECT
        AVG(FLOOR(DATEDIFF(loan.date, c.birth_date) / 365.25)) AS average_age,
        c.gender
    FROM loan
    JOIN financial9_99.account a ON loan.account_id = a.account_id
    JOIN financial9_99.disp d ON a.account_id = d.account_id
    JOIN financial9_99.client c ON c.client_id = d.client_id
    WHERE loan.status IN ('A', 'C')
      AND d.type = 'OWNER'
    GROUP BY c.gender
)
SELECT
    gender_rate.gender,
    gender_rate.loan_count,
    gender_rate.total_amount,
    avg_age.average_age
FROM gender_rate
JOIN avg_age ON avg_age.gender = gender_rate.gender;

-- Client analysis - part 2
-- Make analyses that answer the questions:

-- which area has the most clients,
-- in which area the highest number of loans was paid, - 1
-- in which area the highest amount of loans was paid. - 1
-- Select only owners of accounts as clients.

select count(distinct loan_id),
       sum(amount),a.district_id

from loan

join financial9_99.account a on loan.account_id = a.account_id
join financial9_99.disp d on a.account_id = d.account_id
join financial9_99.client c on c.client_id = d.client_id

where status in ('A', 'C')
AND d.type = 'OWNER'
group by a.district_id
order by sum(amount) desc;

select count(distinct loan_id),
       sum(amount),a.district_id

from loan

join financial9_99.account a on loan.account_id = a.account_id
join financial9_99.disp d on a.account_id = d.account_id
join financial9_99.client c on c.client_id = d.client_id

where status in ('A', 'C')
AND d.type = 'OWNER'
group by a.district_id
order by count(distinct loan_id) desc;

-- Client analysis - part 3
-- Use the query created in the previous task and modify it to determine the percentage of each district in the total amount of loans granted.

SELECT
    COUNT(DISTINCT loan.loan_id),
    SUM(loan.amount),
    a.district_id,
    (SUM(loan.amount) / (SELECT SUM(amount) FROM loan WHERE status IN ('A', 'C'))) * 100 AS district_percentage
FROM loan
JOIN financial9_99.account a ON loan.account_id = a.account_id
JOIN financial9_99.disp d ON a.account_id = d.account_id
JOIN financial9_99.client c ON c.client_id = d.client_id
WHERE loan.status IN ('A', 'C')
  AND d.type = 'OWNER'
GROUP BY a.district_id
ORDER BY COUNT(DISTINCT loan.loan_id) DESC;

-- Selection - part 1
-- Client selection
-- Check the database for the clients who meet the following results:
-- their account balance is above 1000,
-- they have more than 5 loans,
-- they were born after 1990.
-- And we assume that the account balance is loan amount - payments.

select count(loan.loan_id),sum(amount - payments) as balance, c.client_id
from loan
join account a on a.account_id = loan.account_id
join financial9_99.disp d on a.account_id = d.account_id
join client c on d.client_id = c.client_id
where birth_date > '1990-12-31'
AND loan.status IN ('A', 'C')
AND d.type = 'OWNER'
group by c.client_id
having balance > 1000;
-- order by count(loan.loan_id) desc;
    -- count(l.loan_id) > 5
-- NEVIM PROC SE MI TADY NIC NEROBRAZUJE

SELECT
    c.client_id,

    sum(amount - payments) as client_balance,
    count(loan_id) as loans_amount
FROM loan as l
         INNER JOIN
     account a using (account_id)
         INNER JOIN
     disp as d using (account_id)
         INNER JOIN
     client as c using (client_id)
WHERE True
  AND l.status IN ('A', 'C')
  AND d.type = 'OWNER'
--  AND EXTRACT(YEAR FROM c.birth_date) > 1990
GROUP BY c.client_id
HAVING
    sum(amount - payments) > 1000
--    and count(loan_id) > 5
ORDER BY loans_amount DESC; -- here we add descending sorting by number of loans

-- Expiring cards
-- Write a procedure to refresh the table you created (you can call it e.g. cards_at_expiration) containing the following columns:

-- client id,
-- card id,
-- expiration date - assume that the card can be active for 3 years after issue date,
-- client address (column A3 is enough)

DELIMITER $$
DROP PROCEDURE IF EXISTS financial9_99.cards_at_expiration_report_EV;
CREATE PROCEDURE financial9_99.cards_at_expiration_report_EV(p_date DATE)
BEGIN
    TRUNCATE TABLE financial9_99.cards_at_expiration_EV;
    INSERT INTO financial9_99.cards_at_expiration_EV
with cte as (
select c.client_id,
       d.client_id,
       DATE_ADD(card.issued, INTERVAL 3 year) as expiration_date,
    d2.A3 as client_adress

from card
join financial9_99.disp d on card.disp_id = d.disp_id
join financial9_99.client c on d.client_id = card.client_id
join financial9_99.district d2 on c.district_id = d2.district_id
)
select * from cte
WHERE p_date BETWEEN DATE_ADD(expiration_date, INTERVAL -7 DAY) AND expiration_date;
END;
DELIMITER ;
CALL cards_at_expiration_report_EV('2001-01-01');
SELECT * FROM financial9_99.cards_at_expiration_EV;

