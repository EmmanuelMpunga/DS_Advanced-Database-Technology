MPUNGA EMMANUEL 
Reg No: 224019555
African Centre of Excellence in Data Science (ACE-DS)
Masters of Data Science in Mining
UR-CBE Gikondo Campus
Module: Advanced Database and Technology


Case Study: Library Management and Fine System.

1.	Introduction

The Library Management System tracks books, authors, members, borrowing
activities, payments, and staff. Each member borrows books, which must be
returned before the due date. Late returns incur fines recorded in the payment
system.

2.	Project Overview

The Library Management System (LMS) is designed to automate and streamline the management of library resources. 
It handles books, authors, members, borrow, fine and staff. 
The system ensures efficient tracking of borrowing and returning processes while applying fines for late returns.

3.	Core Entities

To manage and organize the library’s collection of books and authors.
To register members and staff for library operations.
To record and monitor borrowing and return activities.
To automatically calculate and record fines for overdue books.


4.	Data Integrity Constraints

a)Primary Keys: Unique identifiers for all entities
b)Foreign Keys: Maintain referential integrity across relationships
c)CHECK Constraints: Validate data quality (e.g., positive stock levels)
d)CASCADE DELETE: Automatic cleanup of related records (Supplier→Product, OrderInfo→OrderDetail etc…)

Below is an Entity Relationship Diagram (ERD) which shows what is in each entity and how entities are related to each other,
with a specification of Primary key and all foreign key. 

5.	Conclusion.

The Library Management System effectively automates and simplifies the daily operations of a library by integrating book tracking, member management, borrowing into a unified platform. Overall, this system contributes significantly to improving library administration and promoting a more organized and user-friendly library environment.