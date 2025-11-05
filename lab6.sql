--PART 1
--Step 1.1
CREATE TABLE employees (
                           emp_id INT PRIMARY KEY,
                           emp_name VARCHAR(50),
                           dept_id INT,
                           salary DECIMAL(10, 2)
);

CREATE TABLE departments (
                             dept_id INT PRIMARY KEY,
                             dept_name VARCHAR(50),
                             location VARCHAR(50)
);

CREATE TABLE projects (
                          project_id INT PRIMARY KEY,
                          project_name VARCHAR(50),
                          dept_id INT,
                          budget DECIMAL(10, 2)
);
--Step 1.2
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES
    (1, 'John Smith', 101, 50000),
    (2, 'Jane Doe', 102, 60000),
    (3, 'Mike Johnson', 101, 55000),
    (4, 'Sarah Williams', 103, 65000),
    (5, 'Tom Brown', NULL, 45000);

INSERT INTO departments (dept_id, dept_name, location)
VALUES
    (101, 'IT', 'Building A'),
    (102, 'HR', 'Building B'),
    (103, 'Finance', 'Building C'),
    (104, 'Marketing', 'Building D');

INSERT INTO projects (project_id, project_name, dept_id, budget)
VALUES
    (1, 'Website Redesign', 101, 100000),
    (2, 'Employee Training', 102, 50000),
    (3, 'Budget Analysis', 103, 75000),
    (4, 'Cloud Migration', 101, 150000),
    (5, 'AI Research', NULL, 200000);

--Part 2
--Ex 2.1

SELECT e.emp_name, d.dept_name
FROM employees e
         CROSS JOIN departments d;
-- N * M

--Ex 2.2

SELECT e.emp_name, d.dept_name
FROM employees e
         INNER JOIN departments d ON TRUE;

--Ex 2.3

SELECT e.emp_name, p.project_name
FROM employees e
         CROSS JOIN projects p;

--Part 3
--Ex 3.1
SELECT e.emp_name, d.dept_name, d.location
FROM employees e
         INNER JOIN departments d ON e.dept_id = d.dept_id;
--Number of rows: 4
--Why Tom Brown is not included:
--INNER JOIN excludes rows where dept_id is missing (NULL does not equal any value).

--Ex 3.2

SELECT emp_name, dept_name, location
FROM employees
         INNER JOIN departments USING (dept_id);

--USING says SQL:
--"Connect these two tables in a column with the SAME NAME,
--and as a result, show this column ONLY ONCE"

--Ex 3.3

SELECT emp_name, dept_name, location
FROM employees
         NATURAL INNER JOIN departments;

--Ex 3.4

SELECT e.emp_name, d.dept_name, p.project_name
FROm employees e
         INNER JOIN departments d ON e.dept_id = d.dept_id
         INNER JOIN projects p ON d.dept_id = p.dept_id;

--Part 4

--Ex 4.1

SELECT e.emp_name, e.dept_id as emp_dept, d.dept_id as dept_dept, d.dept_id
FROM employees e
         LEFT JOIN departments d ON e.dept_id = d.dept_id;

--Ex 4.2

SELECT emp_name, dept_id as emp_dept, dept_id as dept_dept, dept_id
FROM employees
         LEFT JOIN departments USING(dept_id);

--Ex 4.3

SELECT e.emp_name, e.dept_id
FROM employees e
         LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;


--Ex 4.4

SELECT d.dept_name, COUNT(e.emp_id) as employee_count
FROM departments d
         LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;


-- Part 5
-- Ex 5.1

SELECT e.emp_name, d.dept_name
FROM employees e
         RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- Ex 5.2

SELECT e.emp_name, d.dept_name
FROM departments d
         LEFT JOIN employees e ON d.dept_id = e.dept_id;


-- Ex 5.3

SELECT d.dept_name, e.emp_name
FROM employees e
         RIGHT JOIN departments d ON d.dept_id = e.dept_id
WHERE e.emp_id IS NULL;

-- Part 6
-- Ex 6.1

SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id, d.dept_name
FROM employees e
         FULL JOIN departments d ON e.dept_id = d.dept_id;


-- Ex 6.2

SELECT d.dept_name, p.project_name, p.budget
FROM departments d
         FULL JOIN projects p ON p.dept_id = d.dept_id;


-- Ex 6.3

SELECT
    CASE
        WHEN e.emp_id IS NULL THEN 'Department without employees'
        WHEN d.dept_id IS NULL THEN 'Employee without department'
        ELSE 'Matched'
        END AS record_status,
    e.emp_name,
    d.dept_name
FROM employees e
         FULL JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL OR e.dept_id IS NULL;

-- Part 7

-- Ex 7.1
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
         LEFT JOIN departments d ON e.dept_id = d.dept_id
    AND d.location = 'Building A';


-- Ex 7.2

SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
         LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';


-- Ex 7.3

SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
         INNER JOIN departments d ON e.dept_id = d.dept_id
    AND d.location = 'Building A';

SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
         INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';

-- Part 8
-- Ex 8.1
SELECT d.dept_name, e.emp_name, e.salary
FROM departments d
         LEFT JOIN employees e ON d.dept_id = e.dept_id;


-- Ex 8.1

SELECT d.dept_name, e.emp_name, e.salary, p.project_name, p.budget
FROM departments d
         LEFT JOIN employees e ON d.dept_id = e.dept_id
         LEFT JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;


-- Ex 8.2

ALTER TABLE employees ADD COLUMN manager_id INT;

UPDATE employees SET manager_id = 3 WHERE emp_id = 1;
UPDATE employees SET manager_id = 3 WHERE emp_id = 2;
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;
UPDATE employees SET manager_id = 3 WHERE emp_id = 4;
UPDATE employees SET manager_id = 3 WHERE emp_id = 5;

SELECT e.emp_name AS employee, m.emp_name AS manager
FROM employees e
         LEFT JOIN employees m ON e.manager_id = m.emp_id;


-- Ex 8.3
SELECT d.dept_name, AVG(e.salary) AS avg_salary
FROM departments d
         INNER JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;

/*
Lab Questions:

1. INNER JOIN returns only rows that have matches in both tables, while LEFT JOIN returns all rows from the left table and substitutes NULL if there are no matches with the right table.

2. CROSS JOIN is used when it is necessary to get all possible combinations of strings from two datasets, for example, to generate complete combinations of elements.

3. The filter position is important for external connections: the ON condition allows you to save rows from the left table even without matches, and the WHERE condition can delete them. There is no difference for internal connections, since only matching strings are selected in them.

4. The result of the expression SELECT COUNT(*) FROM table1 CROSS JOIN table2 is equal to the product of the number of rows of the first table by the number of rows of the second table. If the first table contains 5 rows and the second contains 10 rows, the final result will be 50 rows.

5. NATURAL JOIN determines the columns to join automatically by selecting all columns with the same name in both tables.

6. The main risks of NATURAL JOIN are that changing the structure of tables (for example, adding identical column names) can lead to unexpected behavior and errors, and this design makes the code less readable.

7. To convert a LEFT JOIN to a RIGHT JOIN, you need to swap tables in the query, keeping the join condition — the result will remain the same.

8. FULL OUTER JOIN is used when it is necessary to get all rows from both tables, including those that do not match in the other table.
*/

-- Additional
-- Ex 1

SELECT A.*, B.*
FROM A LEFT JOIN B ON A.id = B.id
UNION
SELECT A.*, B.*
FROM A RIGHT JOIN B ON A.id = B.id;


-- Ex 2

SELECT e.emp_name, d.dept_name
FROM employees e
         JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IN (
    SELECT dept_id
    FROM projects
    GROUP BY dept_id
    HAVING COUNT(*) > 1
);


-- Ex 3

SELECT
    e1.emp_name AS Employee,
    e2.emp_name AS Manager,
    e3.emp_name AS "Manager's Manager"
FROM employees e1
         LEFT JOIN employees e2 ON e1.manager_id = e2.emp_id
         LEFT JOIN employees e3 ON e2.manager_id = e3.emp_id;


-- Ex 4

SELECT
    e1.emp_name AS Employee1,
    e2.emp_name AS Employee2,
    d.dept_name
FROM employees e1
         JOIN employees e2 ON e1.dept_id = e2.dept_id AND e1.emp_id < e2.emp_id
         JOIN departments d ON e1.dept_id = d.dept_id;