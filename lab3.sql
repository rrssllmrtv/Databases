-- PART A:

CREATE DATABASE advanced_lab;

CREATE TABLE employees (
        emp_id   SERIAL PRIMARY KEY,
        first_name varchar,
        last_name  varchar,
        department varchar,
        salary     int,
        hire_date  date,
        status     varchar DEFAULT 'ACTIVE'
);

CREATE TABLE departments (
        dept_id    SERIAL PRIMARY KEY,
        dept_name  varchar,
        budget     int,
        manager_id int
);

CREATE TABLE projects (
        project_id   SERIAL PRIMARY KEY,
        project_name varchar,
        dept_id      int,
        start_date   date,
        end_date     date,
        budget       int
);


-- PART B:

-- 2)
INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (DEFAULT, 'Rassul', 'Muratov', 'IT');

-- 3)
INSERT INTO employees (first_name, last_name, department, salary, status)
VALUES ('Frank', 'Smith', 'IT', DEFAULT, DEFAULT);

-- 4)
INSERT INTO departments (dept_name, budget, manager_id)
VALUES
    ('Finance',     100000, NULL),
    ('Marketing',   150000, NULL),
    ('Engineering', 200000, NULL);

-- 5)
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Jack', 'Adams', 'IT', (50000 * 1.1)::int, CURRENT_DATE);

-- 6)
CREATE TEMP TABLE temp_employees AS
SELECT *
FROM employees
WHERE department = 'IT';


-- PART C:

-- 7)
UPDATE employees
SET salary = (salary * 1.10)::int;

-- 8)
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < DATE '2020-01-01';

-- 9)
UPDATE employees
SET department = CASE
        WHEN salary > 80000 THEN 'Management'
        WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
        ELSE 'Junior'
    END;

-- 10)
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- 11)
UPDATE departments d
SET budget = (s.avg_salary * 1.20)::int
FROM (
         SELECT department AS dept_name, AVG(salary) AS avg_salary
         FROM employees
         GROUP BY department
     ) s
WHERE d.dept_name = s.dept_name;

-- 12)
UPDATE employees
SET salary = (salary * 1.15)::int,
    status = 'Promoted'
WHERE department = 'Sales';


-- PART D:

-- 13)
DELETE FROM employees
WHERE status = 'Terminated';

-- 14)
DELETE FROM employees
WHERE salary < 40000
        AND hire_date > DATE '2023-01-01'
        AND department IS NULL;

-- 15)
DELETE FROM departments d
WHERE NOT EXISTS (
        SELECT 1
        FROM employees e
        WHERE e.department = d.dept_name
);

-- 16)
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;


-- PART E:

-- 17)
INSERT INTO employees (first_name, last_name, salary, department)
VALUES ('Rassul', 'Muratov', NULL, NULL);

-- 18)
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- 19)
DELETE FROM employees
WHERE salary IS NULL
        OR department IS NULL;


-- PART F:

-- 20)
INSERT INTO employees (first_name, last_name, department, salary)
VALUES ('Rassul', 'Muratov', 'IT', 10000)
RETURNING emp_id, (first_name || ' ' || last_name) AS full_name;

-- 21)
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, salary - 5000 AS old_salary, salary AS new_salary;

-- 22)
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;


-- PART G:

-- 23) Conditional INSERT
INSERT INTO employees (first_name, last_name, department)
SELECT 'Rassul', 'Muratov', 'IT'
WHERE NOT EXISTS (
        SELECT 1 FROM employees
        WHERE first_name = 'Rassul' AND last_name = 'Muratov'
);

-- 24) UPDATE with JOIN logic using subqueries
UPDATE employees e
SET salary = (
    salary * CASE
            WHEN (SELECT d.budget FROM departments d
                WHERE d.dept_name = e.department) > 100000 THEN 1.10
            ELSE 1.05
        END
    )::int;

-- 25) Bulk operations
INSERT INTO employees (first_name, last_name, department, salary) VALUES
        ('Temirlan', 'Yerlanov', 'HR', 65000),
        ('Aizhan', 'Barlasova', 'Engineering', 48000),
        ('Nurlan', 'Turarov', 'Marketing', 72000),
        ('Dastan', 'Satpayev', 'Finance', 42000),
        ('Ainaz', 'Berlen', 'Engineering', 68000);

UPDATE employees
SET salary = salary * 1.10
WHERE first_name IN ('Temirlan', 'Aizhan', 'Nurlan', 'Dastan', 'Ainaz');

CREATE TABLE employee_archive AS
SELECT * FROM employees WHERE status = 'Inactive';

-- 26)
CREATE TABLE employee_archive AS
SELECT * FROM employees WHERE FALSE;

INSERT INTO employee_archive
SELECT * FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

-- 27)
UPDATE projects p
SET end_date = COALESCE(p.end_date, CURRENT_DATE) + INTERVAL '30 days'
WHERE p.budget > 50000
  AND EXISTS (
    SELECT 1
    FROM departments d
             JOIN employees e ON e.department = d.dept_name
    WHERE d.dept_id = p.dept_id
    GROUP BY d.dept_id
    HAVING COUNT(*) > 3
);