Library Management and Fine System

Case Study Overview

This project implements a Library Management System designed to manage books, authors, members, staff, borrowing activities, fines, and payments.
It’s part of Advanced Database Technology coursework and demonstrates key SQL concepts including:

Table creation with constraints

Relationships (1:N and 1:1)

Views and triggers

Cascade deletes

Data manipulation and reporting

Database Schema
Tables

Author (AuthorID, FullName, Nationality, BirthYear)

Book (BookID, Title, AuthorID, Genre, PublicationYear, Status)

Member (MemberID, FullName, Contact, Address, Email)

Staff (StaffID, FullName, Role, Phone, Shift)

Borrow (BorrowID, BookID, MemberID, StaffID, BorrowDate, DueDate, ReturnDate)

Fine (FineID, BorrowID, Amount, PaymentDate, Status)

Relationships

Author → Book (1:N)

Book → Borrow (1:N)

Member → Borrow (1:N)

Staff → Borrow (1:N)

Borrow → Fine (1:1)

All relationships are enforced with foreign keys.
Cascade delete is applied from Borrow → Fine.

Tasks Implemented

Created all six tables with PRIMARY KEY, FOREIGN KEY, and CHECK constraints.

Applied ON DELETE CASCADE from Borrow → Fine.

Inserted sample data for authors, books, and members.

Retrieved all books currently borrowed with their due dates.

Updated fine records when payments are received.

Listed members with overdue returns beyond 7 days.

Created a view summarizing fines collected by month.

Implemented a trigger to mark a book as 'Available' upon return.


Example SQL Code
Author and Book Tables
CREATE TABLE Author (
    AuthorID SERIAL PRIMARY KEY,
    FullName VARCHAR(100),
    Nationality VARCHAR(50),
    BirthYear INT
);

CREATE TABLE Book (
    BookID SERIAL PRIMARY KEY,
    Title VARCHAR(100),
    AuthorID INT,
    Genre VARCHAR(50),
    PublicationYear INT,
    Status VARCHAR(20),
    FOREIGN KEY (AuthorID) REFERENCES Author(AuthorID) ON DELETE CASCADE
);

Insert Sample Data
INSERT INTO Author (FullName, Nationality, BirthYear) VALUES
('Chinua Achebe', 'Nigerian', 1930),
('Wole Soyinka', 'Nigerian', 1934),
('Chimamanda Ngozi Adichie', 'Nigerian', 1977),
('Albert Camus', 'French', 1913),
('George Orwell', 'British', 1903);

Example Queries

Retrieve all borrowed books and due dates

SELECT b.Title, br.DueDate
FROM Book b
JOIN Borrow br ON b.BookID = br.BookID
WHERE br.ReturnDate IS NULL;


List members with overdue returns (7+ days)

SELECT m.FullName, br.DueDate
FROM Member m
JOIN Borrow br ON m.MemberID = br.MemberID
WHERE br.ReturnDate IS NULL
AND CURRENT_DATE - br.DueDate > 7;

Concepts Demonstrated

Data integrity and referential constraints

Cascade operations

Triggers and views

Date calculations and condition checks

Schema creation and cross-schema table movement

Author

Emmanuel Mpunga
Head of IT Division | Data Science Fellow
emmpunga@gmail.com
Adventist University of Central Africa

How to Use

Run the SQL scripts in PostgreSQL or pgAdmin.

Review and execute commands in logical order:

Create tables → Insert data → Run queries/triggers/views.

Modify sample data or extend the schema for testing.

License

This project is provided for academic and learning purposes.
