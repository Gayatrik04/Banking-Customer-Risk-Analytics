CREATE DATABASE banking_customer_risk_analytics;
USE banking_customer_risk_analytics;

CREATE TABLE customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    gender VARCHAR(10),
    age TINYINT,
    marital_status VARCHAR(20),
    occupation VARCHAR(100),
    annual_income INT,
    city VARCHAR(50),
    state VARCHAR(50),
    customer_since DATE,
    customer_segment VARCHAR(20),
    customer_tenure INT
);

CREATE TABLE branches (
    branch_id VARCHAR(10) PRIMARY KEY,
    branch_name VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    region VARCHAR(20),
    employees INT
);

CREATE TABLE accounts (
    account_id VARCHAR(10) PRIMARY KEY,
    customer_id VARCHAR(10),
    account_type VARCHAR(30),
    balance DECIMAL(15,2),
    branch_id VARCHAR(10),
    account_status VARCHAR(20),
    open_date DATE,

    CONSTRAINT fk_account_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT fk_account_branch
        FOREIGN KEY (branch_id)
        REFERENCES branches(branch_id)
);

CREATE TABLE loans (
    loan_id VARCHAR(10) PRIMARY KEY,
    customer_id VARCHAR(10),
    loan_type VARCHAR(50),
    loan_amount DECIMAL(15,2),
    interest_rate DECIMAL(5,4),
    emi DECIMAL(12,2),
    credit_score SMALLINT,
    loan_status VARCHAR(20),
    default_flag VARCHAR(5),
    remaining_balance DECIMAL(15,2),

    CONSTRAINT fk_loan_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);

CREATE TABLE transactions (
    transaction_id VARCHAR(15) PRIMARY KEY,
    customer_id VARCHAR(10),
    account_id VARCHAR(10),
    date DATE,
    transaction_type VARCHAR(20),
    amount DECIMAL(12,2),
    merchant VARCHAR(100),
    payment_mode VARCHAR(30),
    status VARCHAR(20),

    CONSTRAINT fk_transaction_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT fk_transaction_account
        FOREIGN KEY (account_id)
        REFERENCES accounts(account_id)
);







-- Q1. How many customers does the bank have?
select count(customer_id) as total_customer from customers ;

-- Q2. Which customer segment contributes the largest customer base?
select customer_segment,count(customer_id) as customer_base 
from customers group by customer_segment;

-- Q3. Which states have the highest number of customers?
select state,count(customer_id)as total_customer from customers 
group by state order by total_customer desc limit 1;

-- Q4. What is the average annual income by customer segment?
select customer_segment,avg(annual_income)as avg_annual_income from customers
group by customer_segment;

-- Q5. Which occupations contribute the highest average income?
select occupation,avg(annual_income)as avg_income from customers 
group by occupation order by avg_income desc limit 1;

-- Q6. What is the total deposit balance across all accounts?
select round(sum(balance),2)as total_deposit_balance from accounts ;

-- Q7. Which account type has the highest average balance?
select account_type,round(avg(balance),2)as highest_avg_balance from accounts 
group by account_type order by highest_avg_balance desc limit 1;

-- Q8. Which branches manage the highest total balances?
select b.branch_name,round(sum(a.balance),2)as total_balance from accounts a 
join branches b on a.branch_id=b.branch_id
group by b.branch_name order by total_balance desc limit 1;

-- Q9. How many active, dormant, and closed accounts exist?
select account_status,count(account_id)as total_account_exist 
from accounts group by account_status order by total_account_exist desc;

-- Q10. Top 10 customers with the highest account balances.
select c.customer_id,
concat(c.first_name," ",c.last_name)as customer_name,sum(a.balance)as account_balance 
from customers c join accounts a on c.customer_id=a.customer_id 
group by c.customer_id,customer_name order by account_balance desc limit 10;


-- Q11. What is the overall loan default rate?
select round(sum(case when default_flag = "Yes" then 1 else 0 end )*100.0 / count(*),2) as default_rate from loans;

-- Q12. Which loan type has the highest default rate?
select loan_type, round(sum(case when default_flag = "Yes" then 1 else 0 end)*100.0/count(*),2)as default_rate 
from loans group by loan_type order by default_rate desc limit 1;

-- Q13. Which credit score category has the highest default rate?
select  
case when credit_score < 580 then "Poor"
	 when credit_score between 580 and 669 then "Fair"
	 when credit_score between 760 and 739 then "Good"
	 when credit_score between 740 and 799 then "Very Good"
	 else "Excellent"
end as credit_category,
round(sum(case when default_flag = "Yes" then 1 else 0 end)*100.0/count(*),2)as default_rate 
from loans 
group by credit_category order by default_rate desc limit 1;

-- Q14. Which states have the highest loan default rates?
select c.state, round(sum(case when l.default_flag = "Yes" then 1 else 0 end)*100.0/count(loan_id),2)as default_rate 
from customers c join loans l on c.customer_id=l.customer_id
group by c.state order by default_rate desc limit 1;


-- Q15. Top 10 customers with the highest remaining loan balance.
select c.customer_id,concat(c.first_name," ",c.last_name)as customer_name,sum(l.remaining_balance)as remaining_balance
from customers c join loans l on c.customer_id=l.customer_id 
group by c.customer_id,customer_name order by remaining_balance desc limit 10;

-- Q16. Which customer segment has the highest average loan amount?
select c.customer_segment,round(avg(l.loan_amount),2)as avg_loan_amount 
from customers c 
join loans l on c.customer_id=l.customer_id 
group by c.customer_segment order by avg_loan_amount desc limit 1;

-- Q17. Which customers have the highest EMI-to-Income Ratio?
select c.customer_id,concat(c.first_name,' ',c.last_name)as customer_name,c.annual_income,l.emi,
round((l.emi/(c.annual_income / 12))*100,2)as emi_to_income_ratio
from customers c join loans l on c.customer_id=l.customer_id 
order by emi_to_income_ratio desc limit 10;

-- Customers with Active Loans and Defaulted Payments
select c.customer_id,CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
l.loan_type,l.loan_amount,l.credit_score,l.remaining_balance
from customers c
join loans l on c.customer_id = l.customer_id
where l.default_flag = 'Yes'
order by l.remaining_balance DESC;


-- Q18. What is the total transaction value processed?
select ROUND(SUM(amount),2) AS total_transaction_value  from transactions;

-- Q19. Which payment mode is used the most?
select payment_mode,count(transaction_id)as total_transaction_made  
from transactions group by payment_mode order by total_transaction_made desc limit 1;

-- Q20. Which merchants receive the highest transaction volume?
select merchant,count(transaction_id)as transaction_volume from transactions 
group by merchant order by transaction_volume desc limit 1;

-- Q21. Which month has the highest transaction value?
select month(date)as months,sum(amount)as transaction_value from transactions 
group by months order by transaction_value desc;

-- Q22. Which customers perform the highest transaction amounts?
select c.customer_id,concat(first_name," ",last_name)as customer_name,sum(t.amount)as transaction_amount 
from customers c join transactions t on c.customer_id=t.customer_id 
group by c.customer_id,customer_name order by transaction_amount desc limit 10;


-- Q23. Which customer segment maintains the highest average account balance?
select c.customer_segment,round(avg(a.balance),2)as avg_balance_amount 
from customers c join accounts a 
on c.customer_id=a.customer_id
group by c.customer_segment order by avg_balance_amount desc limit 1;

-- Q24. Which branch has the highest number of customers?
select b.branch_name,count(a.customer_id)as total_customer
from branches b join accounts a on b.branch_id=a.branch_id
group by b.branch_name order by total_customer desc ;

-- Q25. Which branch has the highest total deposits?
select b.branch_name,round(sum(a.balance),2)as total_deposits
from branches b join accounts a on b.branch_id=a.branch_id
group by b.branch_name order by total_deposits desc limit 5 ;

-- Q26. What is the average loan amount by income group?
select case when c.annual_income < 500000 then "Low"
when c.annual_income between 500000 and 999999 then "Medium"
when c.annual_income between 1000000 and 1499999 then "Upper"
else "High"
end as income_group,
avg(l.loan_amount)as avg_loan_amount
from customers c join loans l
on c.customer_id=l.customer_id
group by income_group;

-- Q27. Which customer segments have the highest default rates?
select c.customer_segment, round(sum(case when l.default_flag = "Yes" then 1 else 0 end)*100.0/count(l.loan_id),2)as default_rate 
from customers c join loans l on c.customer_id=l.customer_id
group by c.customer_segment order by default_rate desc limit 1;

-- Q28. Which regions generate the highest transaction value?
select b.region,round(sum(t.amount), 2) as transaction_value
from transactions t join accounts a
on t.account_id = a.account_id
join branches b
on a.branch_id = b.branch_id
group by b.region order by transaction_value desc;

-- Q29. Which customers have both high balances and active loans?
select c.customer_id,concat(c.first_name, ' ', c.last_name) as customer_name,
sum(a.balance) as total_balance,l.loan_type,l.loan_amount,l.loan_status
from customers c join accounts a on c.customer_id = a.customer_id
join loans l on c.customer_id = l.customer_id
where l.loan_status = 'active'
group by c.customer_id,customer_name,l.loan_type,l.loan_amount,l.loan_status
order by total_balance desc limit 10;

-- Q30. Rank branches based on total deposits.
select b.branch_name,round(sum(a.balance), 2) as total_deposits,
rank() over(order by sum(a.balance) desc) as branch_rank
from branches b join accounts a
on b.branch_id = a.branch_id
group by b.branch_name;

-- Q31. Rank customers by annual income.
select customer_id,concat(first_name, ' ', last_name) as customer_name,annual_income,
rank() over(order by annual_income desc) as income_rank
from customers;

-- Q32. Rank branches by total deposits.
select b.branch_name,round(sum(a.balance), 2) as total_deposits,
dense_rank() over(order by sum(a.balance) desc) as branch_rank
from branches b join accounts a
on b.branch_id = a.branch_id
group by b.branch_name;

-- Q33. Find the top 3 customers in each state by income.
with ranked_customers as
(
select customer_id,concat(first_name, ' ', last_name) as customer_name,state,annual_income,
row_number() over(partition by state order by annual_income desc) as rn
from customers)

select customer_id,customer_name,state,annual_income from ranked_customers
where rn <= 3;

-- Q34. Compare each customer's balance with the average balance of their account type.
select customer_id,account_type,balance,
round(avg(balance) over(partition by account_type), 2) as avg_account_balance
from accounts;

-- Q35. Find customers whose balances are above the overall average.
select c.customer_id,concat(c.first_name, ' ', c.last_name) as customer_name,a.balance
from customers c join accounts a
on c.customer_id = a.customer_id
where a.balance >
(select avg(balance) from accounts
)
order by a.balance desc;