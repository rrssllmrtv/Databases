--Part 1: DATABASE SETUP

CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100),
    dept_id INT,
    salary DECIMAL(10,2),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE projects (
    proj_id INT PRIMARY KEY,
    proj_name VARCHAR(100),
    budget DECIMAL(12,2),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

INSERT INTO departments VALUES
    (101, 'IT', 'Building A'),
    (102, 'HR', 'Building B'),
    (103, 'Operations', 'Building C');

INSERT INTO employees VALUES
    (1, 'John Smith', 101, 50000),
    (2, 'Jane Doe', 101, 55000),
    (3, 'Mike Johnson', 102, 48000),
    (4, 'Sarah Williams', 102, 52000),
    (5, 'Tom Brown', 103, 60000);

INSERT INTO projects VALUES
    (201, 'Website Redesign', 75000, 101),
    (202, 'Database Migration', 120000, 101),
    (203, 'HR System Upgrade', 50000, 102);




--Part 2: CREATING BASIC INDEXES
--Exercise 2.1
CREATE INDEX emp_salary_idx ON employees(salary);

SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'employees';
-- 2 indexes. One is the automatic index created for the PRIMARY KEY on emp_id, and the other is the new emp_salary_idx on salary.

--Exercise 2.2
CREATE INDEX emp_dept_idx ON employees(dept_id);

SELECT * FROM employees WHERE dept_id = 101;
-- It speeds up JOIN operations with the referenced table

--Exercise 2.3
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
--On departments: departments_pkey (automatic, for PRIMARY KEY on dept_id)
--On employees: employees_pkey (automatic, for PRIMARY KEY on emp_id), emp_salary_idx, emp_dept_idx
--On projects: projects_pkey (automatic, for PRIMARY KEY on proj_id)
--Automatic indexes: All the _pkey ones




--Part 3: Multicolumn Indexes
--Exercise 3.1
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);

SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;
-- PostgreSQL can only use the index efficiently if the leading column
--(dept_id in this case) is included in the filter. Without dept_id, it would fall back to a sequential scan or another index.


--Exercise 3.2
CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);

SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;
SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;
-- Yes, the order matters. The index is most efficient when queries filter on the leading columns first



--Part 4: UNIQUE INDEXES
--Exercise 4.1
ALTER TABLE employees ADD COLUMN email VARCHAR(100);

UPDATE employees SET email = 'john.smith@company.com' WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

INSERT INTO employees(emp_id, emp_name, dept_id, salary, email) VALUES
    (6, 'New Employee', 101, 55000, 'john.smith@company.com');
-- ERROR: duplicate key value violates unique constraint "emp_email_unique_idx"
-- Detail: Key (email)=(john.smith@company.com) already exists.

--Exercise 4.2
ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees' AND indexname LIKE '%phone%';
-- Yes, PostgreSQL automatically created a unique B-tree index
-- named employees_phone_key to enforce the UNIQUE constraint.



--Part 5: INDEXES AND SORTING
--Exercise 5.1
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;
-- It allows PostgreSQL to scan the index in descending order directly, avoiding the need to sort the results after fetching them.

--Exercise 5.2
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

SELECT proj_name, budget
FROM projects
ORDER BY budget NULLS FIRST;



--Part 6: INDEXES ON EXPRESSIONS
--Exercise 6.1
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';
-- It would perform a sequential scan of the table, applying LOWER(emp_name)
-- to every row, which is slower on large tables

--Exercise 6.2
ALTER TABLE employees ADD COLUMN hire_date DATE;

UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;



--Part 7: MANAGING INDEXES
--Exercise 7.1
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

SELECT indexname FROM pg_indexes WHERE tablename = 'employees';


--Exercise 7.2
DROP INDEX emp_salary_dept_idx;
-- To save disk space, reduce overhead
-- on write operations (INSERT/UPDATE/DELETE), or remove redundant/duplicated indexes that aren't used by queries.

--Exercise 7.3
REINDEX INDEX employees_salary_index;
-- After bulk INSERT operations
-- When index becomes bloated
-- After significant data modifications



--Part 8: PRACTICAL SCENARIOS
--Exercise 8.1
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
         JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;

CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;


--Exercise 8.21
CREATE INDEX proj_high_budget_idx ON projects(budget) WHERE budget > 80000;

SELECT proj_name, budget
FROM projects
WHERE budget > 80000;
-- A partial index is smaller and faster to maintain because it only includes rows matching the
-- WHERE condition. It uses less disk space and reduces write overhead for rows outside the condition.

--Exercise 8.3
EXPLAIN SELECT * FROM employees WHERE salary > 52000
-- If Index Scan appears, the planner used an index; Seq Scan means it scanned whole table. It shows Seq Scan


--Part 9: INDEX TYPES COMPARISON
--Exercise 9.1
CREATE INDEX dept_name_hash_idx ON departments USING HASH(dept_name);

SELECT * FROM departments WHERE dept_name = 'IT';
-- Use HASH for equality comparisons (=) on large datasets where B-tree would be slower

--Exercise 9.2
CREATE INDEX proj_name_btree_idx ON projects(proj_name);
CREATE INDEX proj_name_hash_idx ON projects USING HASH(proj_name);

SELECT * FROM projects WHERE proj_name = 'Website Redesign';
SELECT * FROM projects WHERE proj_name > 'Database';



--Part 10: CLEANUP AND BEST PRACTICES
--Exercise 10.1
SELECT schemaname, tablename, indexname, pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
-- In my case, the largest index was the HASH index
-- Hash indexes generally take more space because they store
-- full hash values and lack the hierarchical compression structure of B-trees, resulting in a larger index size.


--Exercise 10.2
DROP INDEX IF EXISTS proj_name_hash_idx;
DROP INDEX IF EXISTS emp_salary_dept_idx;


--Exercise 10.3
CREATE VIEW index_documentations AS
SELECT
    tablename,
    indexname,
    indexdef,
    'Improves salary-based queries' AS purpose
FROM pg_indexes
WHERE schemaname = 'public' AND indexname LIKE '%salary%';

SELECT * FROM index_documentations;