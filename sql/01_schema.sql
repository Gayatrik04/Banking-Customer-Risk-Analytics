CREATE DATABASE IF NOT EXISTS banking_customer_risk_analytics;
USE banking_customer_risk_analytics;

CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    gender VARCHAR(10),
    age TINYINT,
    marital_status VARCHAR(20),
    occupation VARCHAR(100),
    annual_income DECIMAL(15,2),
    city VARCHAR(50),
    state VARCHAR(50),
    customer_since DATE,
    customer_segment VARCHAR(20),
    customer_tenure INT
);

CREATE TABLE IF NOT EXISTS branches (
    branch_id VARCHAR(10) PRIMARY KEY,
    branch_name VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    region VARCHAR(20),
    employees INT
);

CREATE TABLE IF NOT EXISTS accounts (
    account_id VARCHAR(10) PRIMARY KEY,
    customer_id VARCHAR(10),
    account_type VARCHAR(30),
    balance DECIMAL(15,2),
    branch_id VARCHAR(10),
    account_status VARCHAR(20),
    open_date DATE,
    CONSTRAINT fk_account_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_account_branch
        FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);

CREATE TABLE IF NOT EXISTS loans (
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
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE IF NOT EXISTS transactions (
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
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_transaction_account
        FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

-- Recommended indexes for analytical joins and filters
CREATE INDEX idx_accounts_customer ON accounts(customer_id);
CREATE INDEX idx_accounts_branch ON accounts(branch_id);
CREATE INDEX idx_loans_customer ON loans(customer_id);
CREATE INDEX idx_transactions_customer ON transactions(customer_id);
CREATE INDEX idx_transactions_account ON transactions(account_id);
CREATE INDEX idx_transactions_date ON transactions(date);
CREATE INDEX idx_loans_default ON loans(default_flag);


USE banking_customer_risk_analytics;

SELECT 'customers' AS table_name, COUNT(*) AS total_rows FROM customers
UNION ALL
SELECT 'branches', COUNT(*) FROM branches
UNION ALL
SELECT 'accounts', COUNT(*) FROM accounts
UNION ALL
SELECT 'loans', COUNT(*) FROM loans
UNION ALL
SELECT 'transactions', COUNT(*) FROM transactions;

