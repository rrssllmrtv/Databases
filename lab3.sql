--PART A: Database and Table setup
--1:
CREATE DATABASE advanced_lab;

CREATE TABLE employees(
                          emp_id SERIAL PRIMARY KEY,
                          first_name VARCHAR(50),
                          last_name VARCHAR(50),
                          department VARCHAR(50),
                          salary INT,
                          hire_date DATE,
                          status VARCHAR(50) DEFAULT 'Active'
);

CREATE TABLE departments(
                            dept_id SERIAL PRIMARY KEY,
                            dept_name VARCHAR(50),
                            budget INT,
                            manager_id INT
);

CREATE TABLE projects(
                         project_id SERIAL PRIMARY KEY,
                         project_name VARCHAR(50),
                         dept_id INT,
                         start_date DATE,
                         end_date DATE,
                         budget INT
);

--PART B: Advanced INSERT Operations
--2:
INSERT INTO employees (first_name, last_name, department)
VALUES('Denis', 'Zrazhevskiy', 'IT');

--3
INSERT INTO employees (first_name, last_name, department, hire_date, status)
VALUES ('David', 'Black', 'Sales', '2025-09-25', DEFAULT);

--4
INSERT INTO departments (dept_name, budget, manager_id)
VALUES ('Marketing', 120000, 1),
       ('Finance', 200000, 2),
       ('HR', 90000, 3);

--5
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Nurdaulet','Remet','IT',50000 * 1.1,CURRENT_DATE);

--6
CREATE TEMPORARY TABLE temp_employees AS SELECT * FROM employees WHERE department = 'IT';

--PART C: Complex UPDATE Operations
--7
UPDATE employees SET salary = salary * 1.1;

--8
UPDATE employees SET status = 'Senior'
WHERE salary > 60000 AND hire_date < '2020-01-01';

--9
UPDATE employees SET department = CASE
                                      WHEN salary > 80000 THEN 'Management'
                                      WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
                                      ELSE 'Junior'
    END;

--10
UPDATE employees SET department = DEFAULT
WHERE status = 'Inactive';

--11
UPDATE departments SET budget = (SELECT AVG(salary) FROM employees WHERE department = departments.dept_name) * 1.2;

--12
UPDATE employees
SET salary = salary * 1.15, status = 'Promoted'
WHERE department = 'Sales';

--PART D: Advanced DELETE Operations
--13
DELETE FROM employees WHERE status = 'Terminated';

--14
DELETE FROM employees WHERE salary < 40000 AND hire_date > '2023-01-01' AND department IS NULL;

--15
DELETE FROM departments
WHERE dept_name NOT IN(SELECT DISTINCT department FROM employees WHERE department IS NOT NULL);

--16
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

--PART E: Operations with NULL Value
--17
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Alex','Guro',NULL,NULL,'2023-07-12');

--18
UPDATE employees SET department = 'Unassigned' WHERE department IS NULL;

--19
DELETE FROM employees
WHERE salary IS NULL OR department IS NULL;

--PART F: RETURNING Clause Opearions
--20
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Rakhat','Iskhozhin','Sales',50000,'2022-01-02', 'Inactive')
RETURNING emp_id, (first_name || ' ' || last_name) AS full_name;

--21
UPDATE employees SET salary = salary + 10000 WHERE department = 'IT'
RETURNING emp_id, (salary - 10000) AS old_salary, salary AS new_salary;

--22
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

--PART G: Advanced DML Patterns
--23
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Emma','Smith','Sales',95000,'2020-06-12'
WHERE NOT EXISTS(
    SELECT 1 FROM employees WHERE first_name = 'Emma' AND last_name = 'Smith'
);

--24
UPDATE employees SET salary = CASE
                                  WHEN (SELECT budget FROM departments WHERE dept_name = employees.department) > 100000 THEN salary * 1.1
                                  ELSE salary * 1.05
    END;

--25
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Adil','Yessentay','IT',205000,'2018-01-01', 'Active'),
       ('Sam','Smith','Sales',150000,'2024-08-01', 'Terminated'),
       ('William','Skot','HR',60000,'2023-11-11', 'Inactive'),
       ('Anton','Smirnov','IT',190000,'2023-11-11', 'Active'),
       ('Ruslan','Efanov','IT',100000,'2024-09-12', 'Active');


UPDATE employees  SET salary = salary * 1.1
WHERE emp_id IN(
    SELECT emp_id
    FROM employees
    ORDER BY emp_id DESC
    LIMIT 5
);

--26
CREATE TABLE employee_archive AS SELECT * FROM employees WHERE 1 = 0;
INSERT INTO employee_archive SELECT * FROM employees WHERE status = 'Inactive';
DELETE FROM employees WHERE status = 'Inactive';

--27
UPDATE projects SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000 AND (SELECT COUNT(*) FROM employees
                          WHERE department = (SELECT dept_name FROM departments WHERE dept_id = projects.dept_id)) > 3;