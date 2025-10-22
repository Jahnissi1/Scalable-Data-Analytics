# SENG 550: Scalable Data Analytics — Assignment 2

**University of Calgary — Schulich School of Engineering**  
**Course:** SENG 550 — Scalable Data Analytics  
**Assignment** 2
**Instructor:** Rafee Al Ahsan  
**Date:** October 2025 

---

## 📘 Overview

This repository contains our submission for **Assignment 2**, which focused on integrating **PostgreSQL**, **MongoDB**, and **Python ETL** workflows.  
The assignment demonstrates Type-2 Slowly Changing Dimensions (SCD), data migration, and comparative analytics between relational and NoSQL systems.

### 🧩 Main Objectives
1. **Build a PostgreSQL data warehouse** using Type-2 dimension tables and a fact table.
2. **Develop a Python ETL pipeline** to extract, transform, and load PostgreSQL data into MongoDB.
3. **Perform comparative analytics** between SQL and MongoDB queries for consistency and insight.

---

## 🛠️ Technologies Used

| Component | Technology |
|------------|-------------|
| Database (SQL) | PostgreSQL 13+ |
| Database (NoSQL) | MongoDB Community Server 6+ |
| Programming | Python 3.9+ |
| Libraries | `psycopg2-binary`, `pymongo`, `python-dotenv` |
| Tools | pgAdmin4, mongosh |

---

## 📂 Project Structure

```plaintext
├── A2_PT1.sql              # PostgreSQL schema + initial data load
├── A2_PT2.sql              # As-of query definition
├── A2_PT3.sql              # SQL analysis queries
├── etl.py                  # Python ETL script (Postgres → MongoDB)
├── .env                    # Database connection file (excluded)
├── Group10_Assignment2.pdf # Final report with screenshots & explanations
└── README.md               # Project documentation
```






---

## ⚙️ Part Breakdown

### **Part 1 – Build the PostgreSQL Database**
- Created and populated:
  - `dim_customers` (Type-2 dimension)
  - `dim_products` (Type-2 dimension)
  - `fact_orders` (append-only fact table)
- Implemented Type-2 history logic for customer city and product price changes.

### **Part 2 – ETL from PostgreSQL to MongoDB**
- Developed an ETL pipeline that:
  - Reads database credentials from `.env`
  - Executes an *as-of* query joining dimensions with facts
  - Loads transformed data into MongoDB (`sales_db.orders_summary`)
  - Supports **idempotent** operations (no duplicate records)

### **Part 3 – Comparative Analysis**
- Executed equivalent queries in PostgreSQL and MongoDB:
  1. Distinct cities per customer  
  2. Total amount sold by city (at order time)  
  3. Difference between listed price and paid amount  
- Verified consistency across both systems and discussed differences.

---

## 👥 Team Contributions
- Ryan Khryss Obiar
- Rainbow Peng
- Jahnissi Nwakanma
- Bryan Phan

---

## 🧠 Key Insights

- **Type-2 dimensioning** ensures historical accuracy in changing data.
- **ETL idempotency** prevents duplicate MongoDB entries on re-runs.
- Differences between SQL and MongoDB aggregations arise due to:
  - PostgreSQL’s inclusion of historical states.
  - MongoDB’s reliance on as-of transactional views.
- Final totals for sales and price differences matched across systems.

---

## 🚀 How to Run

1. **Set up PostgreSQL and MongoDB** locally.
2. Run the `.sql` files in order:  
   ```bash
   psql -U <user> -d <database> -f A2_PT1.sql
   psql -U <user> -d <database> -f A2_PT2.sql
   psql -U <user> -d <database> -f A2_PT3.sql


## Configure .env file
- PG_HOST=localhost
- PG_DB=sales_db
- PG_USER=postgres
- PG_PASSWORD=yourpassword
- MONGO_URI=mongodb://localhost:27017/


## Run the ETL script
python3 etl.py

