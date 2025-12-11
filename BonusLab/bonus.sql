
--

CREATE TABLE IF NOT EXISTS customers (
    customer_id SERIAL PRIMARY KEY,
    tin VARCHAR(12) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15),
    email VARCHAR(100),
    status VARCHAR(10) CHECK (status IN ('active', 'blocked', 'frozen')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    daily_limit_kzt DECIMAL(15, 2) DEFAULT 500000.00
);

CREATE TABLE IF NOT EXISTS accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id) ON DELETE CASCADE,
    account_number VARCHAR(34) UNIQUE NOT NULL,
    currency VARCHAR(3) CHECK (currency IN ('KZT', 'USD', 'EUR', 'RUB')),
    balance DECIMAL(15, 2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS transactions (
    transaction_id SERIAL PRIMARY KEY,
    from_account_id INT REFERENCES accounts(account_id),
    to_account_id INT REFERENCES accounts(account_id),
    amount DECIMAL(15, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    exchange_rate DECIMAL(10, 4),
    amount_kzt DECIMAL(15, 2),
    type VARCHAR(20) CHECK (type IN ('transfer', 'deposit', 'withdrawal')),
    status VARCHAR(10) CHECK (status IN ('pending', 'completed', 'failed', 'reversed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    description TEXT
);

CREATE TABLE IF NOT EXISTS exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency VARCHAR(3) NOT NULL,
    to_currency VARCHAR(3) NOT NULL,
    rate DECIMAL(10, 4) NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP
);

CREATE TABLE IF NOT EXISTS audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INT,
    action VARCHAR(10) CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(50),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(15)
);

-- Insert data into customers
INSERT INTO customers (tin, full_name, phone, email, status, daily_limit_kzt) VALUES
    ('123456789012', 'Kairat Esenov', '+77775178901', 'kairat@mail.kz', 'active', 1000000),
    ('234567890123', 'Nurislam Beisengali', '+77709817654', 'nuris@mail.kz', 'active', 750000),
    ('345678901234', 'Ernur Maratov', '+77078239012', 'ernur@mail.kz', 'blocked', 500000),
    ('456789012345', 'Aigerim Utepova', '+77701234522', 'aigerim@mail.kz', 'active', 1500000),
    ('567890123456', 'Nurai Zhumabaeva', '+7707718453', 'nurai@mail.kz', 'frozen', 300000),
    ('678901234567', 'Vladimir Olegov', '+77772091659', 'vlad@mail.kz', 'active', 2000000),
    ('789012345678', 'Abzal Martenov', '+77771920401', 'abzal@mail.kz', 'active', 800000),
    ('890123456789', 'Bakyt Temirova', '+77071831354', 'bakyt@mail.kz', 'blocked', 400000),
    ('901234567890', 'Balnur Tulepova', '+77078290185', 'balnur@mail.kz', 'active', 1200000),
    ('012345678901', 'Temirlan Anarbekov', '+77701829423', 'temirlan@mail.kz', 'active', 900000);

-- Insert data into accounts
INSERT INTO accounts (customer_id, account_number, currency, balance, is_active) VALUES
    (1, 'KZ214331561021132491', 'KZT', 500000.00, TRUE),
    (1, 'KZ151927149221587819', 'USD', 10000.00, TRUE),
    (2, 'KZ247153234962169101', 'KZT', 250000.00, TRUE),
    (3, 'KZ412613024171035131', 'EUR', 5000.00, FALSE),
    (4, 'KZ567890123456789012', 'RUB', 300000.00, TRUE),
    (5, 'KZ181942517468890113', 'KZT', 150000.00, TRUE),
    (6, 'KZ282801623799504222', 'USD', 20000.00, TRUE),
    (7, 'KZ830081283718311785', 'KZT', 350000.00, TRUE),
    (8, 'KZ101020048100137816', 'EUR', 3000.00, FALSE),
    (9, 'KZ101965673901274167', 'KZT', 450000.00, TRUE),
    (10, 'KZ124563455663478819', 'USD', 15000.00, TRUE);

-- Insert data into exchange_rates
INSERT INTO exchange_rates (from_currency, to_currency, rate, valid_from) VALUES
    ('USD', 'KZT', 450.00, '2024-01-01'),
    ('EUR', 'KZT', 500.00, '2024-01-01'),
    ('RUB', 'KZT', 5.00, '2024-01-01'),
    ('KZT', 'USD', 0.0022, '2024-01-01'),
    ('KZT', 'EUR', 0.0020, '2024-01-01');


---------------------------------------------------------------------
-- TASK 1

-- 3. Create the process_transfer procedure
CREATE OR REPLACE PROCEDURE process_transfer(
    p_from_account_number VARCHAR(34),
    p_to_account_number VARCHAR(34),
    p_amount DECIMAL(15, 2),
    p_currency VARCHAR(3),
    p_description TEXT DEFAULT NULL,
    OUT p_result TEXT
)
    LANGUAGE plpgsql
AS $$
DECLARE
    v_from_account accounts%ROWTYPE;
    v_to_account accounts%ROWTYPE;
    v_sender_customer customers%ROWTYPE;
    v_daily_spent DECIMAL(15, 2);
    v_exchange_rate DECIMAL(10, 4);
    v_amount_kzt DECIMAL(15, 2);
    v_error_code VARCHAR(10);
    v_error_msg TEXT;
    v_savepoint_name TEXT;
    v_transaction_id INT;
BEGIN
    p_result := 'SUCCESS';
    v_savepoint_name := 'before_transfer';

    SAVEPOINT before_transfer;

    -- 1. Validate and lock both accounts
    SELECT * INTO v_from_account FROM accounts WHERE account_number = p_from_account_number FOR UPDATE;
    SELECT * INTO v_to_account FROM accounts WHERE account_number = p_to_account_number FOR UPDATE;

    IF v_from_account IS NULL THEN
        RAISE EXCEPTION 'Sender account not found' USING ERRCODE = 'A0001';
    END IF;

    IF v_to_account IS NULL THEN
        RAISE EXCEPTION 'Recipient account not found' USING ERRCODE = 'A0002';
    END IF;

    IF NOT v_from_account.is_active OR NOT v_to_account.is_active THEN
        RAISE EXCEPTION 'Account is not active' USING ERRCODE = 'A0003';
    END IF;

    -- 2. Check sender customer status
    SELECT * INTO v_sender_customer FROM customers WHERE customer_id = v_from_account.customer_id;
    IF v_sender_customer.status != 'active' THEN
        RAISE EXCEPTION 'Customer status is not active' USING ERRCODE = 'C0001';
    END IF;

    -- 3. Check sufficient balance
    IF v_from_account.balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient funds' USING ERRCODE = 'B0001';
    END IF;

    -- 4. Handle currency conversion
    IF v_from_account.currency != p_currency THEN
        SELECT rate INTO v_exchange_rate FROM exchange_rates
        WHERE from_currency = p_currency AND to_currency = 'KZT' AND valid_to IS NULL;
        IF v_exchange_rate IS NULL THEN
            RAISE EXCEPTION 'Exchange rate not found' USING ERRCODE = 'E0001';
        END IF;
        v_amount_kzt := p_amount * v_exchange_rate;
    ELSE
        v_amount_kzt := p_amount;
    END IF;

    -- 5. Check daily transaction limit
    SELECT COALESCE(SUM(amount_kzt), 0) INTO v_daily_spent
    FROM transactions
    WHERE from_account_id = v_from_account.account_id
      AND DATE(created_at) = CURRENT_DATE
      AND status = 'completed';

    IF v_daily_spent + v_amount_kzt > v_sender_customer.daily_limit_kzt THEN
        RAISE EXCEPTION 'Daily transaction limit exceeded' USING ERRCODE = 'L0001';
    END IF;

    -- 6. Execute the transfer
    UPDATE accounts SET balance = balance - p_amount WHERE account_id = v_from_account.account_id;
    UPDATE accounts SET balance = balance + p_amount WHERE account_id = v_to_account.account_id;

    -- 7. Record transaction
    INSERT INTO transactions (from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, description, completed_at)
    VALUES (v_from_account.account_id, v_to_account.account_id, p_amount, p_currency, v_exchange_rate, v_amount_kzt, 'transfer', 'completed', p_description, CURRENT_TIMESTAMP)
    RETURNING transaction_id INTO v_transaction_id;

    -- 8. Audit log
    INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by)
    VALUES ('transactions', v_transaction_id, 'INSERT',
            jsonb_build_object('amount', p_amount, 'currency', p_currency, 'description', p_description), 'process_transfer');

    COMMIT;
    p_result := 'Transfer completed successfully';

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO SAVEPOINT before_transfer;
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        p_result := 'ERROR: ' || v_error_msg;

        -- Log failed attempt
        INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by)
        VALUES ('transactions', NULL, 'INSERT',
                jsonb_build_object('error', v_error_msg, 'from_account', p_from_account_number,
                                   'to_account', p_to_account_number, 'amount', p_amount), 'process_transfer');
END;
$$;


---------------------------------------------------------------------
-- TASK 2

-- View 1: customer_balance_summary
CREATE OR REPLACE VIEW customer_balance_summary AS
SELECT
    c.customer_id,
    c.full_name,
    c.tin,
    c.status,
    c.daily_limit_kzt,
    a.account_number,
    a.currency,
    a.balance,
    a.is_active,
    CASE
        WHEN a.currency != 'KZT' THEN a.balance * COALESCE(er.rate, 1)
        ELSE a.balance
        END AS balance_kzt,
    SUM(CASE
            WHEN a.currency != 'KZT' THEN a.balance * COALESCE(er.rate, 1)
            ELSE a.balance
        END) OVER (PARTITION BY c.customer_id) AS total_balance_kzt,
    RANK() OVER (ORDER BY SUM(CASE
                                  WHEN a.currency != 'KZT' THEN a.balance * COALESCE(er.rate, 1)
                                  ELSE a.balance
        END) OVER (PARTITION BY c.customer_id) DESC) AS rank_by_balance,
    COALESCE(SUM(t.amount_kzt) FILTER (WHERE DATE(t.created_at) = CURRENT_DATE AND t.status = 'completed'), 0) AS daily_spent_kzt,
    CASE
        WHEN c.daily_limit_kzt > 0 THEN
            (COALESCE(SUM(t.amount_kzt) FILTER (WHERE DATE(t.created_at) = CURRENT_DATE AND t.status = 'completed'), 0) / c.daily_limit_kzt * 100)
        ELSE 0
        END AS limit_utilization_percent
FROM customers c
         LEFT JOIN accounts a ON c.customer_id = a.customer_id
         LEFT JOIN exchange_rates er ON a.currency = er.from_currency AND er.to_currency = 'KZT' AND er.valid_to IS NULL
         LEFT JOIN transactions t ON a.account_id = t.from_account_id AND t.status = 'completed'
WHERE a.is_active = TRUE
GROUP BY c.customer_id, a.account_id, er.rate;



-- View 2: daily_transaction_report
CREATE OR REPLACE VIEW daily_transaction_report AS
WITH daily_summary AS (
    SELECT
        DATE(created_at) AS transaction_date,
        type,
        COUNT(*) AS transaction_count,
        SUM(amount_kzt) AS total_volume_kzt,
        AVG(amount_kzt) AS avg_amount_kzt
    FROM transactions
    WHERE status = 'completed'
    GROUP BY DATE(created_at), type
)
SELECT
    transaction_date,
    type,
    transaction_count,
    total_volume_kzt,
    avg_amount_kzt,
    SUM(total_volume_kzt) OVER (ORDER BY transaction_date, type) AS running_total_kzt,
    LAG(total_volume_kzt, 1) OVER (ORDER BY transaction_date, type) AS prev_day_volume,
    CASE
        WHEN LAG(total_volume_kzt, 1) OVER (ORDER BY transaction_date, type) > 0
            THEN ((total_volume_kzt - LAG(total_volume_kzt, 1) OVER (ORDER BY transaction_date, type)) / LAG(total_volume_kzt, 1) OVER (ORDER BY transaction_date, type) * 100)
        ELSE NULL
        END AS day_over_day_growth_percent
FROM daily_summary
ORDER BY transaction_date DESC, type;



-- View 3: suspicious_activity_view (WITH SECURITY BARRIER)
CREATE OR REPLACE VIEW suspicious_activity_view WITH (security_barrier = true) AS
-- High amount transactions (> 5,000,000 KZT)
SELECT
    t.transaction_id,
    t.from_account_id,
    t.to_account_id,
    t.amount_kzt,
    t.created_at,
    c.full_name,
    'HIGH_AMOUNT' AS flag_reason,
    'SEVERITY_HIGH' AS severity
FROM transactions t
         JOIN accounts a ON t.from_account_id = a.account_id
         JOIN customers c ON a.customer_id = c.customer_id
WHERE t.amount_kzt > 5000000 AND t.status = 'completed'

UNION ALL

-- High frequency transactions (>10 in 1 hour)
SELECT
    t.transaction_id,
    t.from_account_id,
    t.to_account_id,
    t.amount_kzt,
    t.created_at,
    c.full_name,
    'HIGH_FREQUENCY' AS flag_reason,
    'SEVERITY_MEDIUM' AS severity
FROM transactions t
         JOIN accounts a ON t.from_account_id = a.account_id
         JOIN customers c ON a.customer_id = c.customer_id
WHERE t.created_at >= NOW() - INTERVAL '1 hour' AND t.status = 'completed'
GROUP BY t.from_account_id, c.full_name, t.transaction_id, t.amount_kzt, t.created_at
HAVING COUNT(*) OVER (PARTITION BY t.from_account_id) > 10

UNION ALL

-- Rapid sequential transfers (<1 minute apart)
SELECT DISTINCT
    t1.transaction_id,
    t1.from_account_id,
    t1.to_account_id,
    t1.amount_kzt,
    t1.created_at,
    c.full_name,
    'RAPID_SEQUENTIAL' AS flag_reason,
    'SEVERITY_LOW' AS severity
FROM transactions t1
         JOIN transactions t2 ON t1.from_account_id = t2.from_account_id
    AND t1.transaction_id != t2.transaction_id
    AND t1.created_at < t2.created_at
    AND EXTRACT(EPOCH FROM (t2.created_at - t1.created_at)) < 60
         JOIN accounts a ON t1.from_account_id = a.account_id
         JOIN customers c ON a.customer_id = c.customer_id
WHERE t1.status = 'completed' AND t2.status = 'completed'
ORDER BY created_at DESC;



---------------------------------------------------------------------
-- TASK 3

-- 1. B-tree index on frequently queried column
CREATE INDEX idx_accounts_account_number ON accounts(account_number);

-- 2. Hash index for exact status matching
CREATE INDEX idx_customers_status_hash ON customers USING HASH(status);

-- 3. Composite index for transaction queries
CREATE INDEX idx_transactions_from_date_status ON transactions(from_account_id, created_at DESC, status);

-- 4. Partial index for active accounts only
CREATE INDEX idx_accounts_active_partial ON accounts(account_id) WHERE is_active = TRUE;

-- 5. Expression index for case-insensitive email search
CREATE INDEX idx_customers_email_lower ON customers(LOWER(email));

-- 6. GIN index on JSONB columns in audit_log
CREATE INDEX idx_audit_log_new_values_gin ON audit_log USING GIN(new_values);
CREATE INDEX idx_audit_log_old_values_gin ON audit_log USING GIN(old_values);

-- 7. Covering index for common reporting query
CREATE INDEX idx_transactions_covering ON transactions(from_account_id, status, created_at, amount_kzt, currency, type);

-- 8. Index on exchange_rates for current rates
CREATE INDEX idx_exchange_rates_current ON exchange_rates(from_currency, to_currency) WHERE valid_to IS NULL;

-- 9. Index for daily limit calculations
CREATE INDEX idx_transactions_daily_limit ON transactions(from_account_id, created_at, amount_kzt) WHERE status = 'completed';

-- 10. Composite index for customer lookups
CREATE INDEX idx_customers_tin_status ON customers(tin, status);


---------------------------------------------------------------------
-- TASK 4

CREATE OR REPLACE PROCEDURE process_salary_batch(
    p_company_account_number VARCHAR(34),
    p_payments JSONB,
    OUT p_successful_count INT,
    OUT p_failed_count INT,
    OUT p_failed_details JSONB
)
    LANGUAGE plpgsql
AS $$
DECLARE
    v_company_account accounts%ROWTYPE;
    v_total_amount DECIMAL(15, 2) := 0;
    v_payment JSONB;
    v_iin VARCHAR(12);
    v_amount DECIMAL(15, 2);
    v_description TEXT;
    v_customer_id INT;
    v_account_number VARCHAR(34);
    v_error TEXT;
    v_errors JSONB := '[]'::JSONB;
    v_lock_id BIGINT;
    v_savepoint_name TEXT;
    v_payment_count INT;
    v_current_payment INT := 0;
BEGIN
    p_successful_count := 0;
    p_failed_count := 0;
    p_failed_details := '[]'::JSONB;

    -- Calculate total amount
    SELECT COUNT(*), SUM((value->>'amount')::DECIMAL)
    INTO v_payment_count, v_total_amount
    FROM jsonb_array_elements(p_payments);

    -- Advisory lock to prevent concurrent processing for same company
    v_lock_id := hashtext(p_company_account_number)::bigint % 2147483647;
    PERFORM pg_advisory_lock(v_lock_id);

    -- Start transaction
    BEGIN
        -- Find and lock company account
        SELECT * INTO v_company_account
        FROM accounts
        WHERE account_number = p_company_account_number
            FOR UPDATE;

        IF v_company_account IS NULL THEN
            RAISE EXCEPTION 'Company account not found: %', p_company_account_number;
        END IF;

        IF NOT v_company_account.is_active THEN
            RAISE EXCEPTION 'Company account is not active';
        END IF;

        -- Check company balance
        IF v_company_account.balance < v_total_amount THEN
            RAISE EXCEPTION 'Insufficient funds in company account. Required: %, Available: %',
                v_total_amount, v_company_account.balance;
        END IF;

        -- Process each payment
        FOR v_payment IN SELECT * FROM jsonb_array_elements(p_payments)
            LOOP
                v_current_payment := v_current_payment + 1;
                v_savepoint_name := 'payment_' || v_current_payment;

                SAVEPOINT payment_savepoint;

                BEGIN
                    v_iin := v_payment->>'iin';
                    v_amount := (v_payment->>'amount')::DECIMAL;
                    v_description := COALESCE(v_payment->>'description', 'Salary Payment');

                    IF v_iin IS NULL OR LENGTH(v_iin) != 12 THEN
                        RAISE EXCEPTION 'Invalid IIN: %', v_iin;
                    END IF;

                    -- Find customer by IIN
                    SELECT customer_id INTO v_customer_id
                    FROM customers
                    WHERE tin = v_iin AND status = 'active';

                    IF v_customer_id IS NULL THEN
                        RAISE EXCEPTION 'Active customer with IIN % not found', v_iin;
                    END IF;

                    -- Find active KZT account for customer
                    SELECT account_number INTO v_account_number
                    FROM accounts
                    WHERE customer_id = v_customer_id
                      AND currency = 'KZT'
                      AND is_active = TRUE
                    ORDER BY opened_at DESC
                    LIMIT 1;

                    IF v_account_number IS NULL THEN
                        RAISE EXCEPTION 'No active KZT account found for customer with IIN %', v_iin;
                    END IF;

                    -- Process transfer (bypass daily limit for salary payments)
                    CALL process_transfer(
                            p_from_account_number := p_company_account_number,
                            p_to_account_number := v_account_number,
                            p_amount := v_amount,
                            p_currency := 'KZT',
                            p_description := v_description,
                            p_result := v_error
                         );

                    IF v_error LIKE 'SUCCESS%' OR v_error = 'Transfer completed successfully' THEN
                        p_successful_count := p_successful_count + 1;
                    ELSE
                        RAISE EXCEPTION 'Transfer failed: %', v_error;
                    END IF;

                EXCEPTION
                    WHEN OTHERS THEN
                        ROLLBACK TO SAVEPOINT payment_savepoint;
                        p_failed_count := p_failed_count + 1;
                        v_errors := v_errors || jsonb_build_object(
                                'iin', v_iin,
                                'amount', v_amount,
                                'error', SQLERRM,
                                'payment_index', v_current_payment
                                                );
                        CONTINUE;
                END;
            END LOOP;

        UPDATE accounts
        SET balance = balance - v_total_amount
        WHERE account_id = v_company_account.account_id;

        INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by)
        VALUES ('batch_processing', NULL, 'INSERT',
                jsonb_build_object(
                        'company_account', p_company_account_number,
                        'total_amount', v_total_amount,
                        'successful_count', p_successful_count,
                        'failed_count', p_failed_count,
                        'payment_count', v_payment_count
                ), 'process_salary_batch');

        p_failed_details := v_errors;

        -- Create materialized view for report
        DROP MATERIALIZED VIEW IF EXISTS salary_batch_report;
        CREATE MATERIALIZED VIEW salary_batch_report AS
        SELECT
            p_company_account_number AS company_account,
            CURRENT_TIMESTAMP AS batch_timestamp,
            v_total_amount AS total_amount,
            p_successful_count AS successful_count,
            p_failed_count AS failed_count,
            v_payment_count AS total_payments,
            p_failed_details AS failure_details,
            CASE
                WHEN p_failed_count = 0 THEN 'COMPLETED'
                WHEN p_successful_count > 0 THEN 'PARTIAL'
                ELSE 'FAILED'
                END AS batch_status
        WITH DATA;

        PERFORM pg_advisory_unlock(v_lock_id);

        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_advisory_unlock(v_lock_id);
            RAISE;
    END;
END;
$$;





-- Test cases --------------------------
-- Test 1 ---=====--- Successful transfer
DO $$
    DECLARE
        result TEXT;
    BEGIN
        CALL process_transfer('KZ123456789012345678', 'KZ345678901234567890', 10000.00, 'KZT', 'Test transfer', result);
        RAISE NOTICE 'Test 1 Result: %', result;
    END $$;

-- Test 2 ---=====--- Insufficient funds
DO $$
    DECLARE
        result TEXT;
    BEGIN
        CALL process_transfer('KZ123456789012345678', 'KZ345678901234567890', 1000000.00, 'KZT', 'Large transfer', result);
        RAISE NOTICE 'Test 2 Result: %', result;
    END $$;

-- Test 3 ---=====--- Daily limit exceeded
DO $$
    DECLARE
        result TEXT;
    BEGIN
        CALL process_transfer('KZ123456789012345678', 'KZ345678901234567890', 400000.00, 'KZT', 'Transfer 1', result);
        CALL process_transfer('KZ123456789012345678', 'KZ345678901234567890', 400000.00, 'KZT', 'Transfer 2', result);
        CALL process_transfer('KZ123456789012345678', 'KZ345678901234567890', 300000.00, 'KZT', 'Transfer 3 (should fail)', result);
        RAISE NOTICE 'Test 3 Result: %', result;
    END $$;

-- Test 4 ---=====--- Currency conversion
DO $$
    DECLARE
        result TEXT;
    BEGIN
        CALL process_transfer('KZ234567890123456789', 'KZ567890123456789012', 100.00, 'USD', 'USD to RUB transfer', result);
        RAISE NOTICE 'Test 4 Result: %', result;
    END $$;

-- Test 5 ---=====--- Batch salary processing
DO $$
    DECLARE
        payments JSONB;
        successful INT;
        failed INT;
        details JSONB;
    BEGIN
        payments := '[
          {"iin": "123456789012", "amount": 150000, "description": "January Salary"},
          {"iin": "234567890123", "amount": 180000, "description": "January Salary"},
          {"iin": "456789012345", "amount": 220000, "description": "January Salary"},
          {"iin": "INVALID_IIN", "amount": 100000, "description": "Should fail"}
        ]'::JSONB;

        CALL process_salary_batch('KZ123456789012345678', payments, successful, failed, details);

        RAISE NOTICE 'Batch Result: Successful: %, Failed: %', successful, failed;
        RAISE NOTICE 'Failure Details: %', details;

        SELECT * FROM salary_batch_report;
    END $$;

-- Test 6 ---=====--- View testing
DO $$
    BEGIN
        RAISE NOTICE '=== Customer Balance Summary ===';
        SELECT * FROM customer_balance_summary LIMIT 5;

        RAISE NOTICE '=== Daily Transaction Report ===';
        SELECT * FROM daily_transaction_report LIMIT 5;

        RAISE NOTICE '=== Suspicious Activity View ===';
        SELECT * FROM suspicious_activity_view LIMIT 5;
    END $$;





-- Analyze index effectiveness ------------------
-- Before and after comparison for common queries

-- Query 1: Find account by number
EXPLAIN ANALYZE
SELECT * FROM accounts WHERE account_number = 'KZ123456789012345678';

-- Query 2: Daily transactions for a customer
EXPLAIN ANALYZE
SELECT * FROM transactions
WHERE from_account_id = 1
  AND DATE(created_at) = CURRENT_DATE
  AND status = 'completed';

-- Query 3: Customer search by email (case-insensitive)
EXPLAIN ANALYZE
SELECT * FROM customers WHERE LOWER(email) = LOWER('alisher@mail.kz');

-- Query 4: JSONB query on audit log
EXPLAIN ANALYZE
SELECT * FROM audit_log WHERE new_values @> '{"changed_by": "process_transfer"}';

-- Query 5: Complex view query
EXPLAIN ANALYZE
SELECT * FROM customer_balance_summary WHERE customer_id = 1;





-- Concurrency Testing  ------------------
-- Session 1:
BEGIN;
SELECT * FROM accounts WHERE account_number = 'KZ123456789012345678' FOR UPDATE;
-- Keep this open, don't commit yet

-- Session 2 (run in separate terminal):
BEGIN;
SELECT * FROM accounts WHERE account_number = 'KZ123456789012345678' FOR UPDATE;
-- This will wait for Session 1 to release the lock

-- Session 1:
COMMIT; -- Now Session 2 will proceed

-- Test advisory locks:
-- Session 1:
SELECT pg_advisory_lock(123456);
-- Session 2:
SELECT pg_advisory_lock(123456); -- Will wait