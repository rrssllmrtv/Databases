--Part 2. Theoretical Background
--Task 2.1
/*
A transaction is a sequence of one or more SQL operations that are executed as a single logical unit
of work. Database systems are normally accessed by many users or processes simultaneously, and
transactions help manage concurrent access while maintaining data integrity
*/

--Part 3.
CREATE TABLE accounts (
                          id SERIAL PRIMARY KEY,
                          name VARCHAR(100) NOT NULL,
                          balance DECIMAL(10, 2) DEFAULT 0.00
);
CREATE TABLE products (
                          id SERIAL PRIMARY KEY,
                          shop VARCHAR(100) NOT NULL,
                          product VARCHAR(100) NOT NULL,
                          price DECIMAL(10, 2) NOT NULL
);
-- Insert test data
INSERT INTO accounts (name, balance) VALUES
                                         ('Alice', 1000.00),
                                         ('Bob', 500.00),
                                         ('Wally', 750.00);
INSERT INTO products (shop, product, price) VALUES
    Level Description Phenomena Allowed
    SERIALIZABLE Highest isolation. Transactions appear to
execute serially. None
    REPEATABLE
    READ
    Data read is guaranteed to be the same if read
    again. Phantom reads
    READ
    COMMITTED
    Only sees committed data, but may see
    different data on re-read.
    Non-repeatable reads,
    Phantoms
    READ
    UNCOMMITTED
    Can see uncommitted changes from other
    transactions.
    Dirty reads, Non-repeatable,
    Phantoms
    ('Joe''s Shop', 'Coke', 2.50),
    ('Joe''s Shop', 'Pepsi', 3.00);

--3.2 Task 1: Basic Transaction with COMMIT
BEGIN;
UPDATE accounts SET balance = balance - 100.00
WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100.00
WHERE name = 'Bob';
COMMIT;

/*
a) What are the balances of Alice and Bob after the transaction?
Alice - 900
Bob - 600

b)Why is it important to group these two UPDATE statements in a single transaction?
Потому что перевод — это одно логическое действие:
деньги уходят с одного счёта и приходят на другой.

c) What would happen if the system crashed between the two UPDATE statements without a transaction?
Transaсtion will be broken in half-way
*/


--3.3 Task 2: Using ROLLBACK
BEGIN;
UPDATE accounts SET balance = balance - 500.00
WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';
-- Oops! Wrong amount, let's undo
ROLLBACK;
SELECT * FROM accounts WHERE name = 'Alice';

/*
a) What was Alice's balance after the UPDATE but before ROLLBACK?
Alice balance = 500

b) What is Alice's balance after ROLLBACK
Alice Balance back to 1000

c)In what situations would you use ROLLBACK in a real application?
ROLLBACK нужен, чтобы вернуть базу в безопасное состояние и избежать повреждения данных.
*/

--3.4 Task3: Working with SAVEPOINTs
BEGIN;
UPDATE accounts SET balance = balance - 100.00
WHERE name = 'Alice';
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00
WHERE name = 'Bob';
-- Oops, should transfer to Wally instead
ROLLBACK TO my_savepoint;
UPDATE accounts SET balance = balance + 100.00
WHERE name = 'Wally';
COMMIT;

/*
a) After COMMIT, what are the balances of Alice, Bob, and Wally?
Alice остаётся = 900
Bob = 500
Wally = 750 + 100

b) Was Bob's account ever credited? Why or why not in the final state?
ROLLBACK TO my_savepoint отменил это действие.

c) What is the advantage of using SAVEPOINT over starting a new transaction?
SAVEPOINT позволяет:

откатить только часть транзакции
не терять всю уже выполненную работу
продолжать текущую транзакцию дальше
экономить время и избегать перезапуска всей логики
*/

--3.5  Task 4: Isolation Level Demonstration
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to make changes and COMMIT
-- Then re-run:
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;
Terminal 2 (while Terminal 1 is still running):
BEGIN;
DELETE FROM products WHERE shop = 'Joe''s Shop';
INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Fanta', 3.50);
COMMIT;

/*What data does Terminal 1 see before and after Terminal 2 commits?

Before COMMIT (first SELECT):

| Coke | Pepsi |

After COMMIT (second SELECT):

| Fanta |

READ COMMITTED → каждая команда читает последнюю зафиксированную версию данных.*/

--Ex 3.6
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products
WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2
SELECT MAX(price), MIN(price) FROM products
WHERE shop = 'Joe''s Shop';
COMMIT;

-- Terminal 2:

BEGIN;
INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Sprite', 4.00);
COMMIT;

/*
a) No.
Under REPEATABLE READ, Terminal 1 sees the same snapshot of data throughout the entire transaction.
The new “Sprite” row is invisible to Terminal 1.
Terminal 1 returns the same MAX/MIN as the first query.
b) A phantom read occurs when:
A transaction re-runs a query that returns a set of rows,
and the second time, additional rows appear (or disappear)
because another transaction inserted or deleted matching rows.
c) SERIALIZABLE is the only isolation level that fully prevents phantom reads.
*/

--Ex 3.7
-- Terminal 1:

BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to UPDATE but NOT commit
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to ROLLBACK
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

-- Terminal 2:

BEGIN;
UPDATE products SET price = 99.99
WHERE product = 'Fanta';
-- Wait here (don't commit yet)
-- Then:
ROLLBACK;

/*
a) Yes.
Under READ UNCOMMITTED, Terminal 1 is allowed to read data that Terminal 2 changed but did not commit.
b) A dirty read occurs when:
One transaction reads data that another transaction has modified
but not yet committed
If the second transaction later rolls back, the first transaction has seen invalid data.
So a dirty read means:
“Reading changes that never actually existed.”
c) Because it allows the most dangerous anomalies.
*/

--Part 4
--Ex 4.1
BEGIN;

-- Check if Bob has enough balance
DO $$
    DECLARE
        bob_balance numeric;
    BEGIN
        SELECT balance INTO bob_balance
        FROM accounts
        WHERE name = 'Bob';

        IF bob_balance < 200 THEN
            RAISE EXCEPTION 'Insufficient funds: Bob has only %', bob_balance;
        END IF;
    END $$;

-- Perform the transfer
UPDATE accounts
SET balance = balance - 200
WHERE name = 'Bob';

UPDATE accounts
SET balance = balance + 200
WHERE name = 'Wally';

COMMIT;

--Ex 4.2
BEGIN;

-- 1. Insert a new product
INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Water', 1.00);

-- 2. First savepoint
SAVEPOINT sp1;

-- 3. Update the price
UPDATE products
SET price = 1.50
WHERE product = 'Water';

-- 4. Second savepoint
SAVEPOINT sp2;

-- 5. Delete the product
DELETE FROM products
WHERE product = 'Water';

-- 6. Roll back to first savepoint (Water is restored with price=1.00)
ROLLBACK TO sp1;

COMMIT;


--Ex 4.3
--Scenario 1: READ COMMITTED (default)
--Terminal 1
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT balance FROM accounts WHERE name = 'Bob';   -- Returns 300
-- decides Bob can afford it

UPDATE accounts
SET balance = balance - 250
WHERE name = 'Bob';

-- hold before commit...
--Terminal 2 (before T1 commits)
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT balance FROM accounts WHERE name = 'Bob';   -- Also returns 300 !!!
-- Terminal 2 ALSO thinks Bob can afford it

UPDATE accounts
SET balance = balance - 250
WHERE name = 'Bob';

COMMIT;
--Terminal 1 now commits
COMMIT;

--Scenario 2: REPEATABLE READ (PostgreSQL MVCC)
--Terminal 1
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM accounts WHERE name='Bob';  -- 300
--Terminal 2 (before T1 commits)
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM accounts WHERE name='Bob';  -- 300
UPDATE accounts SET balance=balance - 250 WHERE name='Bob';
COMMIT;
--Terminal 1 tries to update:
UPDATE accounts SET balance = balance - 250 WHERE name='Bob';
--ERROR:
ERROR: could not serialize access due to concurrent update

--Scenario 3: SERIALIZABLE
--Terminal 2 commits first
--Terminal 1 tries to commit:
                                                        ERROR: could not serialize access due to read/write dependencies


--Ex 4.4
--Step 1 — The problem
--Joe updates prices but hasn’t committed yet:
--Terminal 2 (Joe):
BEGIN;
UPDATE products SET price = 10.00 WHERE product='Coke';    -- very high
UPDATE products SET price = 0.10 WHERE product='Fanta';    -- very low
-- Not committed yet
--Sally runs MAX and MIN in two separate SELECTs:
--Terminal 1 (Sally):
SELECT MAX(price) FROM products;
-- sees Coke = 10.00   -> MAX = 10.00

SELECT MIN(price) FROM products;
-- sees Fanta = 0.10   -> MIN = 0.10
/*
If Joe now rolls back, both values disappear.

Sally saw:
MAX  = 10.00
MIN  = 0.10

This is valid mathematically, but the problem is:
Sally used inconsistent data from two different versions of the table.
*/

--Step 2 — The MAX < MIN anomaly demonstration
/*
If Joe updates in between Sally’s two SELECTs and Sally sees a mix of old and new values, she may get impossible results like:
MAX(price) < MIN(price)

Joe updates:
SET price = 0.50 for all products

Sally queries:

Query 1 sees old data:

MAX(price) = 3.50


Query 2 sees new data:

MIN(price) = 0.50


Now:

MAX(3.50) < MIN(0.50) → FALSE, but reversed data could yield contradictions


This inconsistent read demonstrates the anomaly.
*/

--Step 3 — Fix with Transactions
--Sally uses a transaction:
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT MAX(price) FROM products;
SELECT MIN(price) FROM products;

COMMIT;
/*
Under REPEATABLE READ:

Sally sees ONE consistent snapshot

Joe’s updates (if concurrent) become invisible until she finishes

MAX and MIN come from the same version of data

No interleaving anomalies

Problem solved.
*/

--Part 5
/*
#1
a) All-or-nothing.
b) Valid state preserved.
c) No interference.
d) Survives crashes.

#2
a) Saves changes.
b) Undoes changes.

#3
a) When only part of a transaction needs undoing.

#4
a) READ UNCOMMITTED: unsafe, dirty reads.
b) READ COMMITTED: no dirty reads.
c) REPEATABLE READ: stable rows.
d) SERIALIZABLE: fully consistent.

#5
a) Reading uncommitted data.
b) Allowed by READ UNCOMMITTED.

#6
a) Same row read twice returns different values.
b) Happens under READ COMMITTED.

#7
a) New rows appear between two reads.
b) Prevented by SERIALIZABLE (and by PostgreSQL’s REPEATABLE READ).

#8
a) Faster, fewer conflicts, better scalability.

#9
a) Prevent inconsistencies and partial updates during concurrency.

#10
a) They are rolled back automatically.
*/