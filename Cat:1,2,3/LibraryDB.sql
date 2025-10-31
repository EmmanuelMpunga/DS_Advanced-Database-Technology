---MPUNGA EMMANUEL
---Reg No: 224019555
---UR-CBE
---African Centre of Excellence in Data Science(ACE-DS)
---Master's of Data Science in Mining 
---Advanced Database and Technology

---Case Study: Retail inventory and sales management system 

CREATE TABLE author(
supplier_id INT PRIMARY KEY NOT NULL,
firstname varchar(20) NOT NULL,
lastname varchar(20) NOT NULL,
contact varchar(10),
email varchar(25) UNIQUE,
city varchar(10) NOT NULL
);

CREATE TABLE Category(
category_id INT PRIMARY KEY NOT NULL,
category_name VARCHAR(50),
description TEXT NOT NULL
);

CREATE TABLE Product(
product_id INT PRIMARY KEY NOT NULL,
product_name VARCHAR(40) NOT NULL,
purchase_price DECIMAL(10,2),
selling_price DECIMAL(10,2),
current_stock INT DEFAULT 0,
created_by VARCHAR(20) NOT NULL,
category_id INT,
FOREIGN KEY(category_id) REFERENCES Category(category_id) ON DELETE CASCADE
);

CREATE TABLE OrderInfo(
order_info_id INT PRIMARY KEY NOT NULL,
amount NUMERIC (10,2),
order_date DATE DEFAULT CURRENT_DATE,
order_type VARCHAR(255) CHECK(order_type IN('sale','purchase')),
total_qty INT,
status VARCHAR(20) CHECK(status IN('paid','unpaid')),
supplier_id INT,
FOREIGN KEY(supplier_id) REFERENCES Supplier(supplier_id)
);

CREATE TABLE OrderDetail(
order_detail_id INT PRIMARY KEY NOT NULL,
product_id INT,
FOREIGN KEY(product_id) REFERENCES Product(product_id),
quantity INT CHECK(quantity>=0),
unit_price NUMERIC(6,2),
sub_total DECIMAL(10,2) CHECK(sub_total>=0)
);

CREATE TABLE Customers(
customer_id INT PRIMARY KEY,
firstname VARCHAR(20) NOT NULL,
lastname VARCHAR(20)NOT NULL,
email VARCHAR(30) UNIQUE,
phone VARCHAR(20),
city VARCHAR(20) 
);

----------------------------------------------------------------------------------------------------------
---Steps of inserting 10 values in the product table and 3 suppliers
----------------------------------------------------------------------------------------------------------



---(1) Inserting 3 tupples in the Supplier table
-----------------------------------------------------------------------------------------------------------------


INSERT INTO Supplier(supplier_id,firstname,lastname,contact,email,city)
values
(1, 'karangwa','betty','0785044405','ehakizimana55@gmail.com','musanze'),
(2,'plan','boaz','0786256322','gatseeleo@gmail.com', 'Kigali'),
(3,'tumukunde','monica','0788597722','monituku22@gmail.com','rwamagana');
 
 --(2)Inserting 3 tuples in Categories table
------------------------------------------------------------------------------------------------------------------
INSERT INTO Category(category_id,category_name,description)
values
(1,'electronics','gadgets and devices'),
(2,'home appliances','household equipments'),
(3,'agricultural','farming and garden tool');

---(3)Inserting 10 tuble in the Product Table
-------------------------------------------------------------------------------------------------------------------

INSERT INTO Product(product_id,product_name,purchase_price,selling_price,current_stock,created_by,category_id)
values
(1,'computer',1000,1500,10,'emma',1),
(2,'phone',4500,5000,20,'emma',1),
(3,'iron',100,500,50,'kenny',2),
(4, 'refrigerator',2000,3000,5,'enna',2),
(5,'hoe',300,500,10,'emmy',3),
(6,'tractor',15000,20000,2,'emmy',3),
(7,'irrigation pum',1200.35,1300,11,'emmy',3),
(8,'microwave',100.69,2000,6,'kenny',2),
(9,'washing machine',20000,25000,7,'kenny',2),
(10,'television',1000.45,1450.58,30,'emma',1);

-- Addition of customer_id in the table of OrderInfo


 ALTER TABLE OrderInfo ADD COLUMN customer_id INT REFERENCES Customers(customer_id);
 select * from OrderInfo;

 
 ---Addition of order_info_id in the table OrderDetail

 
 ALTER TABLE OrderDetail ADD COLUMN order_info_id INT REFERENCES OrderInfo(order_info_id);
 select * from OrderDetail;

---Retrieving all orders with customer name and total values
--------------------------------------------------------------------------------------------------------

 SELECT 
    c.firstname || ' ' || c.lastname AS customer_name,
    o.order_info_id,
    SUM(od.quantity * od.unit_price) AS total_value,
    o.order_date,
    o.order_type
FROM 
    OrderInfo o
JOIN 
    Customers c ON o.customer_id = c.customer_id
JOIN 
    OrderDetail od ON o.order_info_id = od.order_info_id
GROUP BY 
    c.firstname, c.lastname, o.order_info_id, o.order_date, o.order_type;

-- query used to find the most frequently purchased products
--------------------------------------------------------------------------------------------------
    SELECT 
    p.product_id,
    p.product_name,
    COUNT(od.order_detail_id) AS times_purchased
FROM 
    OrderDetail od
JOIN 
    Product p ON od.product_id = p.product_id
GROUP BY 
    p.product_id, p.product_name
ORDER BY 
    times_purchased DESC;


    ---Updating Stock Level after a product sale 
-----------------------------------------------------------------------------------------------------
--This query updates the current_stock column in the Product table
--by subtracting the quantity sold (from OrderDetail) for each product that was sold.

UPDATE Product
SET current_stock = current_stock - (
    SELECT quantity FROM OrderDetail WHERE product_id = Product.product_id
)
WHERE product_id IN (SELECT product_id FROM OrderDetail);


--Updating OrderDetails for the column called order_info_id
UPDATE OrderDetail
SET order_info_id = 2
WHERE order_detail_id = 1;

UPDATE OrderDetail
SET order_info_id = 3
WHERE order_detail_id = 2;

UPDATE OrderDetail
SET order_info_id = 1
WHERE order_detail_id = 3;

UPDATE OrderDetail
SET order_info_id = 4
 WHERE order_detail_id = 4;

UPDATE OrderDetail
SET order_info_id = 5
WHERE order_detail_id = 5;

SELECT * FROM OrderDetail;

-- making order_info_id the foreign key in OrderDetail table
ALTER TABLE OrderDetail
ADD CONSTRAINT fk_orderinfo
FOREIGN KEY (order_info_id)
REFERENCES OrderInfo(order_info_id)
ON DELETE CASCADE;

---Let me add values in the table called Customers
select * from Customers;
INSERT INTO Customers(customer_id,firstname,lastname,email,phone,city)
values
(1, 'Bakame','didas','hakisemas33@gmail.com','0784033302','Gakenke'),
(2,'Bukwisi','claude','ndimubajc11@gmail.com','0788833347','Burera'),
(3,'Kampire','martini','mkampir32@gmail.com','0788597722','Huye');

--Now its time to update the table Called OrderInfo on the column called customer_id missing values

UPDATE OrderInfo
SET customer_id = 2
WHERE order_info_id = 1;


UPDATE OrderInfo
SET customer_id = 1
WHERE order_info_id = 2;

UPDATE OrderInfo
SET customer_id = 3
WHERE order_info_id = 4;

UPDATE OrderInfo
SET customer_id = 2
WHERE order_info_id = 3;


UPDATE OrderInfo
SET customer_id = 3
WHERE order_info_id = 5;

select * from OrderInfo;
-- making customer_id the foreign key in OrderInfo table
ALTER TABLE OrderInfo
ADD CONSTRAINT fk_customers
FOREIGN KEY (customer_id)
REFERENCES Customers(customer_id)
ON DELETE CASCADE;

-- Create OrderDetail table
CREATE TABLE OrderDetail (
    order_detail_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(6,2) NOT NULL CHECK (unit_price >= 0),
    sub_total NUMERIC(10,2) NOT NULL CHECK (sub_total >= 0),
    order_info_id INTEGER NOT NULL,
    FOREIGN KEY (product_id) REFERENCES Product(ProductID),
    FOREIGN KEY (order_info_id) REFERENCES OrderInfo(OrderID)
);

-- Insert values into OrderDetail table
INSERT INTO OrderDetail (order_detail_id, product_id, quantity, unit_price, sub_total, order_info_id) 
VALUES
(1, 1, 2, 50.00, 100.00, 2),
(2, 2, 1, 75.50, 75.50, 3),
(3, 3, 5, 20.00, 100.00, 1),
(4, 4, 3, 15.25, 45.75, 4),
(5, 5, 4, 10.00, 40.00, 5);