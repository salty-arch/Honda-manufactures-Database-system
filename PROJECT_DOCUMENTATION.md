# Honda DMS — Full Project Documentation

> **Honda Dealership Management System**  
> A web-based database management application with a Flask API backend and SQL Server database.  
> Single-page HTML frontend with dark automotive-luxury UI.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Database Schema — 10 Tables](#2-database-schema--10-tables)
3. [Table Relationships (ERD Summary)](#3-table-relationships-erd-summary)
4. [Stored Procedures — 4 Procedures](#4-stored-procedures--4-procedures)
5. [Triggers — 4 Triggers](#5-triggers--4-triggers)
6. [Views — 5 Views](#6-views--5-views)
7. [Indexes — 13 Indexes](#7-indexes--13-indexes)
8. [Dashboard KPIs](#8-dashboard-kpis)
9. [Management Pages — 10 CRUD Panels](#9-management-pages--10-crud-panels)
10. [Analytics Queries — 36 Analytics](#10-analytics-queries--36-analytics)
11. [Feature: Cancel Contract with Trigger Demo](#11-feature-cancel-contract-with-trigger-demo)
12. [Feature: Status Updates (Parts & Service)](#12-feature-status-updates-parts--service)
13. [Feature: Global Search](#13-feature-global-search)
14. [Feature: CSV Export](#14-feature-csv-export)
15. [API Endpoints](#15-api-endpoints)
16. [How Data Flows](#16-how-data-flows)
17. [How to Navigate the UI](#17-how-to-navigate-the-ui)
18. [Key Concepts Explained](#18-key-concepts-explained)

---

## 1. Architecture Overview

```
+---------------------+       +------------------+       +--------------+
|  honda_dms.html     |  HTTP  |  api.py          |  ODBC  |  SQL Server  |
|  (Single-page app)  |-------|  (Flask server)  |-------|  honda_dms   |
|                     | JSON   |  Port 5000       |        |  Database    |
+---------------------+       +------------------+       +--------------+
```

- **Frontend:** A single `honda_dms.html` file containing all HTML, CSS, and JavaScript. No build tools, no frameworks — just vanilla JS + CSS.
- **Backend:** `api.py` is a Flask server that exposes 5 HTTP endpoints. It connects to SQL Server via `pyodbc`.
- **Database:** SQL Server instance `DESKTOP-K0M3A0H`, database `honda_dms`.
- **Communication:** The HTML file makes `fetch()` calls to `http://localhost:5000`. The API returns JSON. No page reloads — everything is dynamic.

---

## 2. Database Schema — 10 Tables

### 2.1 Plants
Stores manufacturing plant locations and their annual capacity.

| Column | Type | Description |
|--------|------|-------------|
| plant_id | INT (PK, IDENTITY) | Unique plant identifier |
| plant_name | NVARCHAR | e.g. "Honda Lahore Plant" |
| country | NVARCHAR | e.g. "Pakistan" |
| city | NVARCHAR | e.g. "Lahore" |
| annual_capacity | INT | Max vehicles per year |

### 2.2 VehicleModels
Catalog of all vehicle models the company produces/sells.

| Column | Type | Description |
|--------|------|-------------|
| model_id | INT (PK, IDENTITY) | Unique model identifier |
| model_name | NVARCHAR | e.g. "Civic 1.8" |
| category | NVARCHAR | e.g. "Sedan", "SUV" |
| engine_cc | INT | Engine displacement |
| fuel_type | NVARCHAR | "Petrol", "Diesel", "Hybrid", "Electric" |
| transmission | NVARCHAR | "Manual", "Automatic", "CVT" |
| base_price | DECIMAL | Manufacturer's suggested price |

### 2.3 ProductionBatches
Tracks when and where vehicles were produced.

| Column | Type | Description |
|--------|------|-------------|
| batch_id | INT (PK, IDENTITY) | Unique batch identifier |
| plant_id | INT (FK -> Plants) | Which plant produced it |
| model_id | INT (FK -> VehicleModels) | Which model was produced |
| batch_date | DATE | Production date |
| units_produced | INT | Number of units |
| dispatch_date | DATE | When units were shipped to dealerships |

### 2.4 Dealerships
Sales and service locations.

| Column | Type | Description |
|--------|------|-------------|
| dealership_id | INT (PK, IDENTITY) | Unique dealership identifier |
| dealership_name | NVARCHAR | e.g. "Honda Atlas -- Karachi" |
| city | NVARCHAR | City location |
| region | NVARCHAR | Region (North/South/Central) |
| contact_phone | NVARCHAR | Phone number |
| manager_name | NVARCHAR | Manager's name |

### 2.5 Inventory
Individual vehicles at each dealership.

| Column | Type | Description |
|--------|------|-------------|
| vin | NVARCHAR(17) (PK) | Vehicle Identification Number |
| dealership_id | INT (FK -> Dealerships) | Where the vehicle is located |
| model_id | INT (FK -> VehicleModels) | Which model this vehicle is |
| color | NVARCHAR | Exterior color |
| year | INT | Model year |
| status | NVARCHAR | CHECK: 'Available', 'Reserved', 'Sold', 'In Transit' |
| arrival_date | DATE | When the vehicle arrived at the dealership |

### 2.6 Customers
People who buy vehicles and/or book service appointments.

| Column | Type | Description |
|--------|------|-------------|
| customer_id | INT (PK, IDENTITY) | Unique customer identifier |
| full_name | NVARCHAR | Customer's full name |
| phone | NVARCHAR | Phone number |
| email | NVARCHAR | Email address |
| address | NVARCHAR | Physical address |
| cnic | NVARCHAR | National ID number |

### 2.7 SalesContracts
Records of vehicle sales.

| Column | Type | Description |
|--------|------|-------------|
| contract_id | INT (PK, IDENTITY) | Unique contract identifier |
| vin | NVARCHAR(17) (FK -> Inventory) | Which vehicle was sold |
| customer_id | INT (FK -> Customers) | Who bought it |
| dealership_id | INT (FK -> Dealerships) | Where it was sold |
| contract_date | DATE | Sale date |
| agreed_price | DECIMAL | Negotiated price |
| discount | DECIMAL | Discount given |
| tax | DECIMAL | Tax applied |
| payment_mode | NVARCHAR | CHECK: 'Cash', 'Installment', 'Lease' |
| status | NVARCHAR | CHECK: 'Pending', 'Signed', 'Cancelled' |

### 2.8 FinancingPlans
Financing/loan details for contracts.

| Column | Type | Description |
|--------|------|-------------|
| financing_id | INT (PK, IDENTITY) | Unique financing identifier |
| contract_id | INT (FK -> SalesContracts) | Which contract this financing is for |
| bank_name | NVARCHAR | Financier bank name |
| down_payment | DECIMAL | Upfront payment |
| tenure_months | INT | Loan duration in months |
| monthly_installment | DECIMAL | Monthly payment amount |
| interest_rate | DECIMAL | Annual interest rate |

### 2.9 PartsOrders
Replacement parts ordered by dealerships.

| Column | Type | Description |
|--------|------|-------------|
| order_id | INT (PK, IDENTITY) | Unique order identifier |
| dealership_id | INT (FK -> Dealerships) | Which dealership ordered |
| part_name | NVARCHAR | e.g. "Brake Pad Set" |
| part_number | NVARCHAR | OEM part number |
| quantity | INT | Number ordered |
| unit_price | DECIMAL | Price per unit |
| order_date | DATE | When the order was placed |
| status | NVARCHAR | CHECK: 'Pending', 'Dispatched', 'Delivered' |

### 2.10 ServiceAppointments
Vehicle service bookings.

| Column | Type | Description |
|--------|------|-------------|
| appt_id | INT (PK, IDENTITY) | Unique appointment identifier |
| customer_id | INT (FK -> Customers) | Who booked the service |
| dealership_id | INT (FK -> Dealerships) | Which dealership will service it |
| vin | NVARCHAR(17) (FK -> Inventory) | Which vehicle needs service |
| appointment_date | DATE | Scheduled service date |
| service_type | NVARCHAR | CHECK: 'Oil Change', 'Full Service', 'Repair', 'Inspection' |
| status | NVARCHAR | CHECK: 'Scheduled', 'Completed', 'Cancelled' |
| technician_name | NVARCHAR | Assigned technician |

---

## 3. Table Relationships (ERD Summary)

```
Plants ---+
          |
          +--- ProductionBatches ---+
          |                         |
          +--- VehicleModels -------+
                  |
                  +--- Inventory -------------+
                  |          |               |
                  |          |    SalesContracts --- FinancingPlans
                  |          |        |
                  |          |        +--- Customers
                  |          |
                  |          +--- Dealerships ------- PartsOrders
                  |               |
                  |               +--- ServiceAppointments
                  |                    |
                  +--------------------+
```

Key FK relationships:
- Inventory.model_id -> VehicleModels.model_id
- Inventory.dealership_id -> Dealerships.dealership_id
- ProductionBatches.plant_id -> Plants.plant_id
- ProductionBatches.model_id -> VehicleModels.model_id
- SalesContracts.vin -> Inventory.vin
- SalesContracts.customer_id -> Customers.customer_id
- SalesContracts.dealership_id -> Dealerships.dealership_id
- FinancingPlans.contract_id -> SalesContracts.contract_id
- PartsOrders.dealership_id -> Dealerships.dealership_id
- ServiceAppointments.customer_id -> Customers.customer_id
- ServiceAppointments.dealership_id -> Dealerships.dealership_id
- ServiceAppointments.vin -> Inventory.vin

---

## 4. Stored Procedures -- 4 Procedures

Location in UI: DB Features page -> "STORED PROCEDURES" section
How to run: Fill in the form fields on each procedure's panel and click Execute.

### 4.1 sp_RegisterSale -- Atomic Sale Transaction
- **Purpose:** Complete a vehicle sale in one atomic operation.
- **What it does:** Validates the vehicle is Available, inserts a Signed SalesContract, updates Inventory status to Sold. Everything happens inside a BEGIN TRANSACTION ... COMMIT block. If any step fails, everything rolls back.
- **Parameters:** @vin, @customer_id, @dealership_id, @agreed_price, @discount, @tax, @payment_mode
- **Why it exists:** Without this procedure, you would need 3 separate SQL statements (INSERT contract, UPDATE inventory, verify availability). The procedure ensures all-or-nothing execution.

### 4.2 sp_CustomerProfile -- Multi-Result Profile
- **Purpose:** Get a complete customer profile in one database call.
- **What it does:** Returns 3 result sets: (1) Customer info, (2) All contracts, (3) Full service history
- **Parameters:** @customer_id
- **Why it matters:** Reduces 3 API calls to 1. The Flask endpoint GET /customer-profile/<id> handles the multi-result-set parsing.

### 4.3 sp_MonthlySalesReport -- Revenue Breakdown
- **Purpose:** Generate a dealership's monthly sales performance.
- **What it does:** Returns 2 result sets: (1) Detail - every signed contract that month with net amount, (2) Summary - total revenue, average sale price, number of contracts
- **Parameters:** @dealership_id, @year, @month
- **Business value:** Management can quickly see how each dealership performed in a given month.

### 4.4 sp_BookService -- Duplicate Guard
- **Purpose:** Book a service appointment with duplicate prevention.
- **What it does:** Before inserting, checks if the same VIN already has a Scheduled appointment on that date. If yes, it raises an error. If no, it proceeds with the insert.
- **Parameters:** @customer_id, @dealership_id, @vin, @appointment_date, @service_type, @technician_name
- **Why it is useful:** Prevents double-booking at the database level -- no application code needed to guard against this.

---

## 5. Triggers -- 4 Triggers

Location in UI: DB Features page -> "TRIGGERS" section
What are triggers? Database objects that automatically execute code when INSERT/UPDATE/DELETE operations happen on a table. They fire automatically -- no application code needed.

### 5.1 trg_ContractSigned_UpdateInventory
- **Type:** AFTER INSERT, UPDATE on SalesContracts
- **Behavior:** When a contract's status is set to 'Signed', this trigger automatically sets the corresponding Inventory VIN's status to 'Sold'.
- **Where to see it in action:** DB Features page -> first trigger panel. Enter a VIN and click "Show Inventory Status".

### 5.2 trg_PreventDoubleSale
- **Type:** INSTEAD OF INSERT on SalesContracts
- **Behavior:** Before allowing a new contract to be inserted, checks whether the vehicle's Inventory status is already 'Sold'. If it is, raises an error and blocks the INSERT.
- **Where to see it in action:** DB Features page -> second trigger panel. Enter a VIN that is already Sold and click "Attempt Double Sale".

### 5.3 trg_ContractCancelled_RestoreInventory
- **Type:** AFTER UPDATE on SalesContracts
- **Behavior:** When a contract's status is updated to 'Cancelled', this trigger automatically sets the vehicle's Inventory status back to 'Available'.
- **Where to see it in action:** Contracts page -> Cancel Contract sub-tab, OR DB Features page -> third trigger panel.

### 5.4 trg_ContractPending_ReserveInventory
- **Type:** AFTER INSERT on SalesContracts
- **Behavior:** When a Pending contract is inserted, automatically sets the vehicle's Inventory status to 'Reserved' so it cannot be sold to someone else while the contract is being negotiated.
- **Where to see it in action:** DB Features page -> fourth trigger panel.

Why triggers over application code? Triggers guarantee the rule runs no matter how the data changes -- whether through the UI, a direct SQL query, a data import, or any future application. The database enforces the business rule at the data level.

---

## 6. Views -- 5 Views

Location in UI: DB Features page -> "VIEWS" section
What are views? Saved SQL queries that act like virtual tables. They encapsulate complex JOINs so you can SELECT * FROM vw_Name instead of writing the JOIN every time.

| View | What it shows |
|------|---------------|
| vw_InventoryFull | Every inventory record with human-readable dealership name and model name |
| vw_SignedContracts | All completed sales with net amount (agreed_price - discount + tax) |
| vw_DealershipRevenue | Revenue summary grouped by dealership |
| vw_AvailableStock | Available units per model |
| vw_ServiceHistory | Full service log per VIN with customer and dealership details |

How to use: Select a view from the dropdown in the DB Features page and click "SELECT * FROM View".

---

## 7. Indexes -- 13 Indexes

Location in UI: DB Features page -> "INDEXES" section
What are indexes? Database structures that speed up data retrieval -- like a book's index. Without indexes, SQL Server has to scan every row (table scan). With indexes, it can jump directly to the relevant rows.

Where to see them: Click "Show All Indexes" on the DB Features page. This queries the SQL Server system tables (sys.indexes, sys.index_columns, etc.) to list all indexes in the database.

The indexes are on FK columns and commonly-searched columns (VIN, status, dates, etc.) to speed up the 67+ queries used in this project.

---

## 8. Dashboard KPIs

Location in UI: Home page (Dashboard)

When the page loads, 8 KPI cards are populated:

| KPI Card | SQL Query |
|----------|-----------|
| Revenue | SELECT SUM(agreed_price-discount+tax), COUNT(*) FROM SalesContracts WHERE status='Signed' |
| Available Vehicles | SELECT COUNT(*) FROM Inventory WHERE status='Available' |
| Total Contracts | SELECT COUNT(*) FROM SalesContracts |
| Pending Contracts | SELECT COUNT(*) FROM SalesContracts WHERE status='Pending' |
| Customers | SELECT COUNT(*) FROM Customers |
| Parts Orders | SELECT COUNT(*) FROM PartsOrders (also shows pending count) |
| Service Appointments | SELECT COUNT(*) FROM ServiceAppointments (also shows scheduled count) |
| Sold Vehicles | SELECT COUNT(*) FROM Inventory WHERE status='Sold' |

Additional dashboard panels: Most Recent Sale (5-table JOIN), Top Dealership by Revenue (aggregation), Pending Parts Orders (Top 5 by wait time), Inventory Breakdown (status distribution per dealership).

---

## 9. Management Pages -- 10 CRUD Panels

Each management page has sub-tabs for specific operations:

| Page | Sub-tabs | Key Operations |
|------|----------|----------------|
| Plants | Modify + Query | Insert/update plant, filter by country or capacity |
| Vehicle Models | Modify + Query | Insert/update model, filter by category, fuel, price range |
| Production | Query only | View batches (JOINs Plants + Models), filter by plant/model |
| Dealerships | Modify + Query | Insert/update dealership, filter by city or region |
| Inventory | Update + Query | Insert vehicle, update status, filter by dealership/VIN/status, stock count |
| Customers | Modify + Query | Insert/update customer, search by name/phone/CNIC |
| Contracts | Cancel + Query | Cancel contract (see trigger demo), filter by customer/status, revenue |
| Financing Plans | Query only | View financing plans, filter by bank or contract |
| Parts Orders | Update + Query | Insert order, update status, filter by dealership/status/spend |
| Service | Update + Query | Insert appointment, update status, filter by customer/VIN/status |

---

## 10. Analytics Queries -- 36 Analytics

Location in UI: Analytics page -> 6 category sub-tabs

### 10.1 Inventory Analytics (5 queries)
- Dealership with most available vehicles (GROUP BY + ORDER BY COUNT)
- Vehicles sitting longest unsold (DATEDIFF + ORDER BY)
- Models completely out of stock (LEFT JOIN + HAVING SUM(CASE)=0)
- Full VIN list per dealership (3-table JOIN)
- Status breakdown per dealership (pivot with SUM(CASE))

### 10.2 Customer Analytics (6 queries)
- Full customer contract view (5-table JOIN)
- Customers who bought >1 vehicle (GROUP BY + HAVING COUNT > 1)
- Customers with no service (NOT IN subquery -- upsell opportunity)
- Biggest spender (SUM + GROUP BY + ORDER BY DESC)
- Contracts with vs without financing (LEFT JOIN)
- Most active financing bank (GROUP BY aggregates)

### 10.3 Sales Analytics (5 queries)
- Dealership revenue ranking (LEFT JOIN + GROUP BY)
- Best-selling vehicle model (LEFT JOIN chain)
- Revenue by payment mode (GROUP BY)
- Cancelled contracts detail (5-table JOIN + WHERE)
- Dealerships with most pending contracts (LEFT JOIN)

### 10.4 Parts Analytics (4 queries)
- Parts ordered per dealership with costs (calculated column)
- Pending deliveries (WHERE Pending + DATEDIFF)
- Highest parts spender (GROUP BY + SUM)
- Parts ordered by multiple dealerships (HAVING COUNT(DISTINCT) > 1)

### 10.5 Service Analytics (5 queries)
- Most frequent service customer (GROUP BY + ORDER BY COUNT DESC)
- VINs serviced multiple times (GROUP BY + HAVING)
- Dealer with most completed jobs (pivot SUM(CASE))
- Technician workload ranking (GROUP BY)
- Sold vehicles never serviced (NOT IN subquery -- follow-up opportunity)

### 10.6 Cross-Domain Analytics (5 queries)
- Full vehicle history by VIN (UNION ALL across 4 tables)
- Dealers that sold AND later serviced (self-join on VIN + dealer)
- Installment buyers who returned for service (multi-table JOIN)
- Models with parts shortage risk (LEFT JOIN + CASE risk flag)
- Inventory >6 months unsold (DATEADD + DATEDIFF)

---

## 11. Feature: Cancel Contract with Trigger Demo

Location: Contracts page -> Cancel Contract sub-tab

Steps:
1. Enter a Contract ID
2. System queries current contract status and Inventory status (BEFORE)
3. Updates contract to status='Cancelled' (fires trg_ContractCancelled_RestoreInventory automatically)
4. Queries Inventory status again (AFTER)
5. Displays 3-column comparison: Contract info | Inventory BEFORE | Inventory AFTER
6. If the trigger works: old status -> Available (proving the trigger fired at database level)

SQL involved:
```sql
-- Get contract details
SELECT contract_id, vin, status, customer_id FROM SalesContracts WHERE contract_id=?
-- Get inventory BEFORE
SELECT vin, status FROM Inventory WHERE vin=?
-- Cancel contract (fires trigger automatically)
UPDATE SalesContracts SET status='Cancelled' WHERE contract_id=?
-- Get inventory AFTER (shows trigger effect)
SELECT vin, status FROM Inventory WHERE vin=?
```

---

## 12. Feature: Status Updates (Parts & Service)

Parts Orders (Parts Orders page -> Update sub-tab):
```sql
UPDATE PartsOrders SET status=? WHERE order_id=?
```
Status options: Pending -> Dispatched -> Delivered

Service Appointments (Service page -> Update sub-tab):
```sql
UPDATE ServiceAppointments SET status=? WHERE appt_id=?
```
Status options: Scheduled -> Completed -> Cancelled

Both use the generic POST /write API endpoint.

---

## 13. Feature: Global Search

Location: Top-right search bar (visible on every page)

Fires a UNION ALL query across 3 tables with 300ms debounce (minimum 2 chars):

```sql
SELECT 'Customer' AS type, customer_id AS id, full_name AS name, phone AS info, '' AS vin
FROM Customers WHERE full_name LIKE ? OR phone LIKE ? OR cnic LIKE ?
UNION ALL
SELECT 'Vehicle' AS type, 0, vm.model_name + ' - ' + i.color, i.status, i.vin
FROM Inventory i JOIN VehicleModels vm ON i.model_id=vm.model_id WHERE i.vin LIKE ?
UNION ALL
SELECT 'Contract' AS type, contract_id, sc.status + ' - ' + sc.payment_mode, c.full_name, sc.vin
FROM SalesContracts sc JOIN Customers c ON sc.customer_id=c.customer_id WHERE sc.vin LIKE ?
ORDER BY type, name
```

Results appear in a dropdown. Clicking navigates to the relevant page.

---

## 14. Feature: CSV Export

A green "CSV" button appears in the footer of every query table.

How it works:
1. Collects current table headers and data rows
2. Escapes commas, quotes, and newlines in cell values
3. Prepends UTF-8 BOM for Excel compatibility
4. Creates a Blob download: honda_dms_export_YYYY-MM-DD.csv

All done client-side -- no server interaction.

---

## 15. API Endpoints

| Endpoint | Method | Purpose | Used By |
|----------|--------|---------|---------|
| /query | POST | Run any SELECT query | All query panels, KPIs, analytics, search |
| /write | POST | Run INSERT/UPDATE/DELETE | All forms, status updates, cancel |
| /register-sale | POST | Run sp_RegisterSale | DB Features page |
| /book-service | POST | Run sp_BookService | DB Features page |
| /customer-profile/<id> | GET | Run sp_CustomerProfile | DB Features page |
| /monthly-report | POST | Run sp_MonthlySalesReport | DB Features page |
| /ping | GET | Health check | Connection status indicator |
| / | GET | Serve honda_dms.html | Browser |

---

## 16. How Data Flows

Read flow (example: loading "All Plants"):
1. User clicks sub-tab -> JS builds query config
2. fetch(POST /query, {sql, params})
3. Flask api.py -> run_query() -> pyodbc -> SQL Server
4. SQL Server returns columns + rows
5. Flask returns JSON -> JS renderTable() builds HTML table
6. Table rendered in the panel's result div

Write flow (example: inserting a plant):
1. User fills form -> JS collects values
2. dbWrite() -> fetch(POST /write, {sql, params})
3. Flask -> run_write() -> cursor.execute() + conn.commit()
4. Response: {ok: true}
5. JS shows success toast + refreshes table

Stored Procedure flow (sp_RegisterSale):
1. User fills form -> JS fetch(POST /register-sale, body)
2. Flask calls EXEC sp_RegisterSale @vin=?, @customer_id=?, ...
3. SQL Server: BEGIN TRAN -> validate -> INSERT -> UPDATE inventory -> COMMIT
4. Response: {ok: true} OR rollback with error

---

## 17. How to Navigate the UI

Sidebar (left, fixed):

| Icon | Page | What you can do there |
|------|------|----------------------|
| 0x25c7 | Dashboard | View KPIs, recent sale, top dealer, pending parts, inventory breakdown |
| 0x21bb | Plants | Add/Modify/Query plants |
| 0x25c8 | Vehicle Models | Add/Modify/Query models |
| 0x2699 | Production | Query production batches |
| 0x25ce | Dealerships | Add/Modify/Query dealerships |
| 0x25f1 | Inventory | Add/Modify/Query vehicles |
| 0x2630 | Customers | Add/Modify/Query customers |
| 0x25ea | Contracts | Cancel Contract + Query |
| 0x25c8 | Financing | Query financing plans |
| 0x229e | Parts Orders | Update Status + Query |
| 0x25f7 | Service | Update Status + Query |
| 0x26a1 | DB Features | Run stored procs, test triggers, query views, list indexes |
| 0x25d4 | Analytics | 36 queries in 6 categories |

Top bar: Page title (changes dynamically) | Global search bar

---

## 18. Key Concepts Explained

### What is a Primary Key (PK)?
A column (or combination) that uniquely identifies each row. Example: customer_id in Customers. PKs are automatically indexed and enforce uniqueness.

### What is a Foreign Key (FK)?
A column referencing a PK in another table, creating a relationship. Example: SalesContracts.customer_id -> Customers.customer_id. FKs prevent orphaned records and maintain referential integrity.

### What is a CHECK Constraint?
A rule restricting column values. Example: Inventory.status CHECK (status IN ('Available','Reserved','Sold','In Transit')) -- prevents invalid values.

### What is a Trigger?
A database object that auto-executes code on INSERT/UPDATE/DELETE. Fires automatically -- no application code needed. Used for:
- Auditing (log changes)
- Enforcement (block double-sales)
- Cascading (auto-restore inventory on cancel)

This project uses 4 triggers: 3 AFTER triggers and 1 INSTEAD OF trigger.

### What is a Stored Procedure?
A saved batch of SQL statements running on the server. Benefits:
- Atomicity: All steps succeed or fail together (transaction)
- Performance: Less network traffic (send just procedure name + params)
- Reusability: Same logic from any application
- Security: Grant execute without direct table access

### What is a View?
A saved SELECT query acting as a virtual table. Benefits:
- Simplifies complex JOINs behind SELECT * FROM vw_Name
- Consistent data transformation for all applications

### What is an Index?
A structure speeding up data retrieval. Without indexes = table scan (slow). With indexes = direct lookup (fast). This project has 13 indexes on FK columns and filtered columns.

### Why parameterized queries?
All SQL uses ? placeholders instead of string concatenation. This prevents SQL injection -- SQL Server treats parameters as data, not executable code.

### How is data integrity maintained?
1. Foreign Keys -- prevent orphan records
2. CHECK constraints -- reject invalid statuses
3. Triggers -- enforce business rules automatically
4. Transactions in stored procedures -- atomicity
5. Parameterized queries -- prevent SQL injection
6. IDENTITY columns -- auto-generate unique IDs

### Where to look for specific things

| Question | Go to |
|----------|-------|
| Is the database connected? | Dashboard (green dot top-right) |
| What tables exist? | DB Features -> Indexes -> Show All Indexes |
| What is the latest sale? | Dashboard -> Most Recent Sale panel |
| Which vehicles are available? | Inventory -> Query -> Available Stock |
| Cancel a contract? | Contracts -> Cancel Contract |
| Test a trigger? | DB Features -> TRIGGERS section |
| Run a stored procedure? | DB Features -> STORED PROCEDURES section |
| Search across everything? | Top-right search bar |
| Export table to Excel? | Green CSV button below any table |
| Customers with no service? | Analytics -> Customer -> "Contract but no service" |
| Aging inventory (>6 months)? | Analytics -> Cross-Domain -> "Inventory >6 months unsold" |
| Total revenue? | Dashboard -> Revenue KPI |
| Parts shortage risk? | Analytics -> Cross-Domain -> "Popular models with low parts" |
