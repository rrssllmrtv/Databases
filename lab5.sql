--Muratov Rassul
--24B031888

--PART 1
--Task 1.1:

CREATE TABLE employees (

                           employee_id SERIAL PRIMARY KEY,
                           first_name text,
                           last_name text,
                           age int CHECK (age BETWEEN 18 AND 65),
                           salary numeric CHECK (salary > 0)

);

--Task 1.2:

CREATE TABLE products_catalog (

                                  product_id SERIAL PRIMARY KEY,
                                  product_name text,
                                  regular_price numeric,
                                  discount_price numeric

                                      CONSTRAINT valid_discount CHECK (

                                          regular_price > 0 AND
                                          discount_price > 0 AND
                                          discount_price < regular_price

                                          )
);

--Task 1.3:

CREATE TABLE bookings (

                          booking_id SERIAL PRIMARY KEY,
                          check_in_date date,
                          check_out_date date,
                          num_guests int

                              CONSTRAINT booking_valid CHECK (

                                  num_guests BETWEEN 1 AND 12 AND
                                  check_out_date > check_in_date
                                  )
);

--Task 1.4:

--Valid inserts:

INSERT INTO employees (first_name, last_name, age, salary)
VALUES ('Ada', 'Lovelace', 30, 4200),
       ('Alan', 'Turing', 41, 7000);

-- NonValid inserts:

INSERT INTO employees (first_name, last_name, age, salary)
VALUES ('Young', 'Kid', 17, 1000);  -- age < 18 → violates CHECK (age BETWEEN 18 AND 65)

INSERT INTO employees (first_name, last_name, age, salary)
VALUES ('Zero', 'Pay', 25, 0);  -- salary ≤ 0 → violates CHECK (salary > 0)


--PART 2

--Task 2.1:

CREATE TABLE customers (

                           customer_id SERIAL PRIMARY KEY NOT NULL,
                           email text NOT NULL,
                           phone text,
                           registration_date date NOT NULL

);

--Task 2.2:

CREATE TABLE inventory (

                           item_id SERIAL PRIMARY KEY NOT NULL,
                           item_name text NOT NULL,
                           quantity int NOT NULL CHECK (quantity >= 0),
                           unit_price numeric NOT NULL CHECK (unit_price > 0),
                           last_updated timestamp NOT NULL

);

--Task 2.3:

ALTER TABLE inventory ADD COLUMN description TEXT;

INSERT INTO inventory (item_name, quantity, unit_price, last_updated, description)
VALUES
    ('Laptop', 10, 1200.00, NOW(), 'Powerful ultrabook'),
    ('Mouse', 50, 25.00, NOW(), 'Wireless mouse');

INSERT INTO inventory (item_name, quantity, unit_price, last_updated)
VALUES (NULL, 10, 50.00, NOW());

INSERT INTO inventory (item_name, quantity, unit_price, last_updated)
VALUES ('Keyboard', NULL, 70.00, NOW());

INSERT INTO inventory (item_name, quantity, unit_price, last_updated)
VALUES ('Monitor', 5, NULL, NOW());

INSERT INTO inventory (item_name, quantity, unit_price, last_updated)
VALUES ('Desk', 3, 200.00, NULL);

INSERT INTO inventory (item_name, quantity, unit_price, last_updated, description)
VALUES ('Chair', 15, 60.00, NOW(), NULL);


--PART 3

--Task 3.1:

CREATE TABLE users (

                       user_id SERIAL PRIMERY KEY,
                       username text UNIQUE,
                       email text UNIQUE,
                       created_at timestamp

);

--Task 3.2:

CREATE TABLE course_enrollments (

                                    enrollment_id SERIAL PRIMARY KEY,
                                    student_id int,
                                    course_code text,
                                    semester text,
                                    CONSTRAINT unique_enrollment UNIQUE (student_id, course_code, semester)

);

--Task 3.3:

ALTER TABLE users
    ADD CONSTRAINT unique_username UNIQUE (username);

ALTER TABLE users
    ADD CONSTRAINT unique_email UNIQUE (email);

INSERT INTO users (username, email)
VALUES ('john_doe', 'new_john@example.com');
--ERROR:  duplicate key value violates unique constraint "unique_username"

INSERT INTO users (username, email)
VALUES ('new_alice', 'alice@example.com');
-- ERROR:  duplicate key value violates unique constraint "unique_email"


--PART 4

--Task 4.1:

CREATE TABLE departments (

                             dept_id SERIAL PRIMARY KEY,
                             dept_name text NOT NULL,
                             location text

);

-- Insert valid data:

INSERT INTO departments (dept_id, dept_name, location)
VALUES
    (1, 'Human Resources', 'New York'),
    (2, 'Finance', 'London'),
    (3, 'IT', 'Berlin');

-- Try to insert duplicate dept_id (1 already exists)

INSERT INTO departments (dept_id, dept_name, location)
VALUES (1, 'Marketing', 'Paris');
--ERROR:  duplicate key value violates unique constraint "departments_pkey"

-- Try to insert NULL in dept_id

INSERT INTO departments (dept_id, dept_name, location)
VALUES (NULL, 'Legal', 'Rome');
--ERROR:  null value in column "dept_id" violates not-null constraint

--Task 4.2:

CREATE TABLE student_courses (

                                 student_id int,
                                 course_id int,
                                 enrollment_date date,
                                 grade text,
                                 PRIMARY KEY (student_idm course_id)

);

--TASK 4.3: Comparison Exercise
-- 1. The difference between UNIQUE and PRIMARY KEY
--    UNIQUE ensures no duplicates in the column, allows NULL per column
--    PRIMARY KEY is UNIQUE + NOT NULL, and there's only one per table.
-- 2. When to use a single-column vs. composite PRIMARY KEY
--    Use a single-column PRIMARY KEY when one column can uniquely identify each record.
--    Use a composite PRIMARY KEY when multiple columns are needed to guarantee uniqueness
-- 3. Why a table can have only one PRIMARY KEY but multiple UNIQUE constraints
--    PRIMARY KEY is the main identifier for the table, used for referencing.
--    Multiple UNIQUE for additional uniqueness requirements on other columns.

--PART 5

--Task 5.1:

CREATE TABLE employees_dept (

                                emp_id INTEGER PRIMARY KEY,
                                emp_name text NOT NULL,
                                dept_id int REFERENCES departments(dept_id),
                                hire_date date
);

-- Insert with correct dept_id (exist in departments)
INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date)
VALUES
    (1, 'Alice Johnson', 1, '2024-03-01'),
    (2, 'Bob Smith', 2, '2024-03-05'),
    (3, 'Charlie Brown', 3, '2024-03-10');

-- Insert with inctorrect dept_id (wxample, 10)
INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date)
VALUES (4, 'David Wilson', 10, '2024-03-15');
-- ERROR:  insert or update on table "employees_dept"
-- violates foreign key constraint "employees_dept_dept_id_fkey"
-- DETAIL:  Key (dept_id)=(10) is not present in table "departments".

--Task 5.2:

CREATE TABLE authors (

                         author_id SERIAL PRIMARY KEY,
                         author_name text NOT NULL,
                         country text

);

CREATE TABLE publishers (

                            publisher_id SERIAL PRIMARY KEY,
                            publisher_name text NOT NULL,
                            city text

);

CREATE TABLE books (

                       book_id SERIAL PRIMARY KEY,
                       title text NOT NULL,
                       author_id int REFERENCES authors(author_id),
                       publisher_id int REFERENCES publishers(publisher_id),
                       publication_year int,
                       isbn text UNIQUE

);

INSERT INTO authors (author_name, country)
VALUES
    ('George Orwell', 'United Kingdom'),
    ('Haruki Murakami', 'Japan'),
    ('Jane Austen', 'United Kingdom');

INSERT INTO publishers (publisher_name, city)
VALUES
    ('Penguin Books', 'London'),
    ('Vintage', 'New York'),
    ('HarperCollins', 'London');

INSERT INTO books (title, author_id, publisher_id, publication_year, isbn)
VALUES
    ('1984', 1, 1, 1949, '9780451524935'),
    ('Animal Farm', 1, 1, 1945, '9780451526342'),
    ('Norwegian Wood', 2, 2, 1987, '9780375704024'),
    ('Kafka on the Shore', 2, 2, 2002, '9781400079278'),
    ('Pride and Prejudice', 3, 3, 1813, '9780062870600');

--Task 5.3:
CREATE TABLE categories(
                           category_id INTEGER PRIMARY KEY,
                           category_name TEXT NOT NULL
);

CREATE TABLE products_fk(
                            product_id INTEGER PRIMARY KEY,
                            product_name TEXT NOT NULL,
                            category_id INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders_task5_3(
                               order_id INTEGER PRIMARY KEY,
                               order_date DATE NOT NULL
);

CREATE TABLE order_items(
                            item_id INTEGER PRIMARY KEY,
                            order_id INTEGER REFERENCES orders_task5_3(order_id) ON DELETE CASCADE,
                            product_id INTEGER REFERENCES products_fk(product_id),
                            quantity INTEGER CHECK (quantity > 0)
);

INSERT INTO categories (category_id, category_name) VALUES (1, 'Gadgets');
INSERT INTO categories (category_id, category_name) VALUES (2, 'something');
INSERT INTO products_fk (product_id, product_name, category_id) VALUES (1, 'Laptop', 1);
INSERT INTO products_fk (product_id, product_name, category_id) VALUES (2, 'Smartphone', 2);
INSERT INTO orders_task5_3 (order_id, order_date) VALUES (1, '2025-08-15');
INSERT INTO orders_task5_3 (order_id, order_date) VALUES (2, '2025-10-02');
INSERT INTO order_items (item_id, order_id, product_id, quantity) VALUES (1, 1, 1, 5);
INSERT INTO order_items (item_id, order_id, product_id, quantity) VALUES (2, 2, 2, 10);

--Test 1: Try to delete a category that has products
--DELETE FROM categories WHERE category_id = 1;
--Result: Fail because products_fk has product referencing it.

--Test 2: Delete an order and observe that order_items are automatically deleted
DELETE FROM orders_task5_3 WHERE order_id = 1;
--Result: Order deleted, and order_items with order_id=1 are automatically deleted.

--Test 3:
-- In the 1st test Fail because products_fk has product referencing it.
-- In hte 2nd test Order deleted, and order_items with order_id=1 are automatically deleted.



--PART 6

--Task 6.1:

CREATE TABLE customers(
                          customer_id SERIAL NOT NULL PRIMARY KEY,
                          name text NOT NULL,
                          email text NOT NULL UNIQUE,
                          phone text NOT NULL UNIQUE,
                          registration_date date NOT NULL default current_date
);

CREATE TABLE products(
                         product_id SERIAL NOT NULL PRIMARY KEY,
                         name text NOT NULL UNIQUE,
                         description text,
                         price numeric(10,2) NOT NULL CHECK(price>=0),
                         stock_quantity int CHECK(stock_quantity >= 0)
);

CREATE TABLE orders(
                       order_id SERIAL NOT NULL PRIMARY KEY,
                       customer_id int REFERENCES customers(customer_id) ON DELETE RESTRICT,
                       order_date date default current_date,
                       total_amount numeric(10,2) NOT NULL default 0 CHECK(total_amount >= 0),
                       status text NOT NULL CHECK (status IN ('pending','paid','shipped','cancelled','completed'))
);

CREATE TABLE order_details(
                              order_detail_id SERIAL NOT NULL PRIMARY KEY,
                              order_id int REFERENCES orders(order_id) ON DELETE CASCADE,
                              product_id int REFERENCES products(product_id) ON DELETE RESTRICT,
                              quantity int NOT NULL CHECK(quantity >= 0),
                              unit_price numeric(10,2) NOT NULL CHECK (unit_price >= 0),
                              UNIQUE (order_id, product_id)
);