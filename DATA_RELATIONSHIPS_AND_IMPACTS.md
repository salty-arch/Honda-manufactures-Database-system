# Honda DMS — Data Relationships & Action Impacts

> **How tables connect, how actions ripple through the database, and what happens when you click a button.**

---

## Table of Contents

1. [The Big Picture: All 10 Tables & Their Links](#1-the-big-picture-all-10-tables--their-links)
2. [Foreign Key Map: Who References Whom](#2-foreign-key-map-who-references-whom)
3. [Trigger Impact Map: Automatic Side Effects](#3-trigger-impact-map-automatic-side-effects)
4. [Stored Procedure Impact Map](#4-stored-procedure-impact-map)
5. [Action → Impact Catalog](#5-action--impact-catalog)
   - [5.1 Add a Plant](#51-add-a-plant)
   - [5.2 Add a Vehicle Model](#52-add-a-vehicle-model)
   - [5.3 Record a Production Batch](#53-record-a-production-batch)
   - [5.4 Add a Dealership](#54-add-a-dealership)
   - [5.5 Add a Vehicle to Inventory](#55-add-a-vehicle-to-inventory)
   - [5.6 Register a Customer](#56-register-a-customer)
   - [5.7 Create a Sales Contract](#57-create-a-sales-contract)
   - [5.8 Sign a Contract (Pending → Signed)](#58-sign-a-contract-pending--signed)
   - [5.9 Cancel a Contract](#59-cancel-a-contract)
   - [5.10 Attempt a Double Sale](#510-attempt-a-double-sale)
   - [5.11 Start a Financing Plan](#511-start-a-financing-plan)
   - [5.12 Order Parts](#512-order-parts)
   - [5.13 Book a Service Appointment](#513-book-a-service-appointment)
   - [5.14 Run sp_RegisterSale (Atomic Sale)](#514-run-sp_registersale-atomic-sale)
   - [5.15 Run sp_CustomerProfile](#515-run-sp_customerprofile)
   - [5.16 Run sp_MonthlySalesReport](#516-run-sp_monthlysalesreport)
   - [5.17 Run sp_BookService](#517-run-sp_bookservice)
6. [Data Integrity Rules](#6-data-integrity-rules)
7. [What Happens When You Violate a Rule](#7-what-happens-when-you-violate-a-rule)

---

## 1. The Big Picture: All 10 Tables & Their Links

### Entity Relationship Diagram (Text)

```
  PLANTS ────────────┐
                     │
                     ├── PRODUCTIONBATCHES ──┐
                     │                       │
  VEHICLEMODELS ─────┘                       │
                     │                       │
                     └── INVENTORY ──────────┤
                         │                   │
                         │    SALESCONTRACTS ─┤── FINANCINGPLANS
                         │        │          │
                         │        └── CUSTOMERS
                         │
                         └── DEALERSHIPS ──── PARTSORDERS
                              │
                              └── SERVICEAPPOINTMENTS
                                   │
                                   └── CUSTOMERS (same)
```

### The Data Flow Chain

```
  Plants ── produce ──► ProductionBatches ── ship to ──► Dealerships
                                                                
  VehicleModels ── define ──► Inventory (at Dealerships)
                                                                
  Customers ── buy ──► SalesContracts ── may have ──► FinancingPlans
                      │
                      └── changes Inventory status (via trigger)
                                                                
  Dealerships ── order ──► PartsOrders
                                                                
  Customers ── book ──► ServiceAppointments (at Dealerships, for a VIN)
```

---

## 2. Foreign Key Map: Who References Whom

Every foreign key creates a link where one table's data depends on another.

| FK Column | Source Table | Target Table | What It Means |
|-----------|-------------|-------------|---------------|
| `ProductionBatches.plant_id` | ProductionBatches | Plants | Every batch must be assigned to a real plant |
| `ProductionBatches.model_id` | ProductionBatches | VehicleModels | Every batch produces a real model |
| `Inventory.dealership_id` | Inventory | Dealerships | Every vehicle sits at a real dealership |
| `Inventory.model_id` | Inventory | VehicleModels | Every vehicle is a real model |
| `SalesContracts.vin` | SalesContracts | Inventory | Every contract references a real VIN |
| `SalesContracts.customer_id` | SalesContracts | Customers | Every contract belongs to a real customer |
| `SalesContracts.dealership_id` | SalesContracts | Dealerships | Every contract is signed at a real dealership |
| `FinancingPlans.contract_id` | FinancingPlans | SalesContracts | Every financing plan attaches to a real contract |
| `PartsOrders.dealership_id` | PartsOrders | Dealerships | Every order is placed by a real dealership |
| `ServiceAppointments.customer_id` | ServiceAppointments | Customers | Every booking is for a real customer |
| `ServiceAppointments.dealership_id` | ServiceAppointments | Dealerships | Every booking is at a real dealership |
| `ServiceAppointments.vin` | ServiceAppointments | Inventory | Every booking is for a real VIN |

**Impact of these FKs:** You CANNOT insert a record in a child table unless the parent record already exists. Example: you cannot insert a SalesContract for VIN 'X' unless that VIN already exists in the Inventory table.

---

## 3. Trigger Impact Map: Automatic Side Effects

Triggers are the database's way of automatically doing something when data changes. They fire WITHOUT any application code.

| Trigger Name | Fires On | What It Does Automatically | Tables Affected |
|-------------|----------|---------------------------|-----------------|
| `trg_ContractSigned_UpdateInventory` | AFTER INSERT or UPDATE on SalesContracts | If new/existing contract status = 'Signed', sets Inventory.status = 'Sold' for that VIN | Inventory (UPDATE) |
| `trg_PreventDoubleSale` | INSTEAD OF INSERT on SalesContracts | If the VIN is already 'Sold' in Inventory, RAISERROR and BLOCK the insert | Prevents SalesContracts insert |
| `trg_ContractCancelled_RestoreInventory` | AFTER UPDATE on SalesContracts | If updated status = 'Cancelled', sets Inventory.status = 'Available' for that VIN | Inventory (UPDATE) |
| `trg_ContractPending_ReserveInventory` | AFTER INSERT on SalesContracts | If new contract status = 'Pending', sets Inventory.status = 'Reserved' for that VIN | Inventory (UPDATE) |

### Trigger Chain Diagram

```
  INSERT SalesContracts (status='Pending')
    │
    └──► trg_ContractPending_ReserveInventory fires
          └──► Inventory.status = 'Reserved'  (auto)

  INSERT SalesContracts (status='Signed')
    │
    ├──► trg_PreventDoubleSale fires
    │     ├── IF Inventory.status = 'Sold' → BLOCK insert
    │     └── IF Inventory.status != 'Sold' → allow insert
    │
    └──► trg_ContractSigned_UpdateInventory fires
          └──► Inventory.status = 'Sold'  (auto)

  UPDATE SalesContracts SET status = 'Cancelled'
    │
    └──► trg_ContractCancelled_RestoreInventory fires
          └──► Inventory.status = 'Available'  (auto)

  UPDATE SalesContracts SET status = 'Signed'
    │
    └──► trg_ContractSigned_UpdateInventory fires
          └──► Inventory.status = 'Sold'  (auto)
```

---

## 4. Stored Procedure Impact Map

| Procedure | Tables Read | Tables Written | Key Impact |
|-----------|------------|---------------|------------|
| `sp_RegisterSale` | Inventory (check status) | SalesContracts (INSERT), Inventory (UPDATE) | Atomically: validates availability → inserts signed contract → marks vehicle as Sold |
| `sp_CustomerProfile` | Customers, SalesContracts, ServiceAppointments | None (read-only) | Returns 3 result sets in one call |
| `sp_MonthlySalesReport` | SalesContracts, Dealerships | None (read-only) | Returns detailed + summary sales data |
| `sp_BookService` | ServiceAppointments (check duplicate) | ServiceAppointments (INSERT) | Prevents double-booking same VIN on same date |

---

## 5. Action → Impact Catalog

Every action you perform in the UI has a measurable impact on the database. Below is a complete catalog with SQL examples.

---

### 5.1 Add a Plant

**UI Location:** Plants page → Add Plant sub-tab  
**SQL executed:**
```sql
INSERT INTO Plants (plant_name, country, city, annual_capacity)
VALUES ('Honda Lahore Plant', 'Pakistan', 'Lahore', 50000);
```

**Tables affected:** Plants only (1 INSERT)  
**Cascading impact:** None directly, but this plant can now be referenced by ProductionBatches  
**What happens if you delete this plant:** ProductionBatches referencing this plant_id will be blocked by FK constraint (unless they are deleted first)  
**Example future use:** `INSERT INTO ProductionBatches (plant_id, ...) VALUES (1, ...)` where 1 = this plant

---

### 5.2 Add a Vehicle Model

**UI Location:** Vehicle Models page → Add Model sub-tab  
**SQL executed:**
```sql
INSERT INTO VehicleModels (model_name, category, engine_cc, fuel_type, transmission, base_price)
VALUES ('Civic 1.8', 'Sedan', 1799, 'Petrol', 'Automatic', 3800000);
```

**Tables affected:** VehicleModels only (1 INSERT)  
**Cascading impact:** This model can now be produced in ProductionBatches and added to Inventory  
**Future chain:**
```
VehicleModels (model_id=5)
  → ProductionBatches (produces 100 units of model_id=5)
    → Inventory (100 vehicles, each with model_id=5, different VINs)
      → SalesContracts (each sale references a VIN which has model_id=5)
```

---

### 5.3 Record a Production Batch

**UI Location:** Production page → Add Batch sub-tab (if available)  
**SQL executed:**
```sql
INSERT INTO ProductionBatches (plant_id, model_id, batch_date, units_produced, dispatch_date)
VALUES (1, 3, '2024-06-01', 50, '2024-06-15');
```

**Tables affected:** ProductionBatches (1 INSERT)  
**Impact on Plants:** Must reference existing plant_id — cannot reference a non-existent plant  
**Impact on VehicleModels:** Must reference existing model_id — cannot reference a non-existent model  
**Downstream:** The 50 units produced here will eventually appear as individual Inventory records when added via the Inventory page

---

### 5.4 Add a Dealership

**UI Location:** Dealerships page → Add Dealership sub-tab  
**SQL executed:**
```sql
INSERT INTO Dealerships (dealership_name, city, region, contact_phone, manager_name)
VALUES ('Honda Atlas — Karachi', 'Karachi', 'South', '021-111-1234', 'Farhan Ali');
```

**Tables affected:** Dealerships only (1 INSERT)  
**Cascading impact:** This dealership can now:
- Receive Inventory vehicles (`Inventory.dealership_id`)
- Sign SalesContracts (`SalesContracts.dealership_id`)
- Order Parts (`PartsOrders.dealership_id`)
- Book Service appointments (`ServiceAppointments.dealership_id`)

---

### 5.5 Add a Vehicle to Inventory

**UI Location:** Inventory page → Add Vehicle sub-tab  
**SQL executed:**
```sql
INSERT INTO Inventory (vin, dealership_id, model_id, color, year, status, arrival_date)
VALUES ('JHMFC1F30MX000008', 1, 3, 'Pearl White', 2024, 'Available', '2024-06-20');
```

**Tables affected:** Inventory only (1 INSERT)  
**FK constraints validated:**
- `dealership_id` must exist in Dealerships
- `model_id` must exist in VehicleModels

**Future chain:** This VIN can now be:
- Referenced in a SalesContract
- Booked for service
- Searched in Global Search
- Shown in inventory analytics

**What happens if you try to add a duplicate VIN:** PK violation error — VIN is the primary key

---

### 5.6 Register a Customer

**UI Location:** Customers page → Add Customer sub-tab  
**SQL executed:**
```sql
INSERT INTO Customers (full_name, phone, email, address, cnic)
VALUES ('Ali Raza', '0300-1234567', 'ali@email.com', 'House 12, DHA Lahore', '35202-1234567-1');
```

**Tables affected:** Customers only (1 INSERT)  
**Cascading impact:** This customer can now:
- Sign SalesContracts (referenced by `customer_id`)
- Book ServiceAppointments (referenced by `customer_id`)

---

### 5.7 Create a Sales Contract

**UI Location:** Contracts page → New Contract sub-tab  
**SQL executed:**
```sql
INSERT INTO SalesContracts (vin, customer_id, dealership_id, contract_date,
                            agreed_price, discount, tax, payment_mode, status)
VALUES ('JHMFC1F30MX000002', 1, 1, '2024-06-25',
        5200000, 100000, 260000, 'Cash', 'Signed');
```

**Tables directly affected:** SalesContracts (1 INSERT)  
**Triggers that fire (AUTOMATIC):**

| Scenario | Trigger | What Happens Automatically |
|----------|---------|---------------------------|
| status = 'Signed' | `trg_ContractSigned_UpdateInventory` | Inventory.status changes to 'Sold' for this VIN |
| status = 'Pending' | `trg_ContractPending_ReserveInventory` | Inventory.status changes to 'Reserved' for this VIN |
| VIN is already Sold | `trg_PreventDoubleSale` | INSERT is BLOCKED — error raised |

**Full impact example (status='Signed'):**
```sql
-- Your action:
INSERT INTO SalesContracts (...) VALUES ('JHMFC1F30MX000002', ..., 'Signed');

-- After trigger fires (no code needed):
-- Inventory table now shows:
-- SELECT status FROM Inventory WHERE vin = 'JHMFC1F30MX000002'
-- Returns: 'Sold'   ← automatically changed by trigger
```

**Contracts that CAN be viewed or modified later by:**  
- Cancel Contract page (sets status to 'Cancelled', which fires another trigger)
- Financing Plans can be added referencing this contract_id

---

### 5.8 Sign a Contract (Pending → Signed)

**UI Location:** This is done via a direct SQL UPDATE (or through the database)  
**SQL executed:**
```sql
UPDATE SalesContracts SET status = 'Signed' WHERE contract_id = 1;
```

**Tables directly affected:** SalesContracts (1 UPDATE)  
**Triggers that fire:**
- `trg_ContractSigned_UpdateInventory` fires on UPDATE  
  → `Inventory.status = 'Sold'` for the VIN in this contract

**What was the old status?** If it was 'Pending', Inventory was 'Reserved'. Now it becomes 'Sold'.  
**What happens to the customer?** They now appear in "Most Recent Sale" on the dashboard.  
**What happens to revenue?** The Revenue KPI increases by (agreed_price - discount + tax).

---

### 5.9 Cancel a Contract

**UI Location:** Contracts page → Cancel Contract sub-tab  
**SQL executed:**
```sql
UPDATE SalesContracts SET status = 'Cancelled' WHERE contract_id = 1;
```

**Tables directly affected:** SalesContracts (1 UPDATE)  
**Triggers that fire:**
- `trg_ContractCancelled_RestoreInventory` fires on UPDATE  
  → `Inventory.status = 'Available'` for the VIN in this contract

**Complete chain of events:**
```
Before:
  SalesContracts(contract_id=1): status='Signed'
  Inventory(vin='JHMFC1F30MX000002'): status='Sold'

Action: Cancel Contract #1

Step 1: UPDATE SalesContracts SET status='Cancelled' WHERE contract_id=1
Step 2: TRIGGER FIRES: trg_ContractCancelled_RestoreInventory
Step 3: UPDATE Inventory SET status='Available' WHERE vin='JHMFC1F30MX000002'

After:
  SalesContracts(contract_id=1): status='Cancelled'
  Inventory(vin='JHMFC1F30MX000002'): status='Available'
```

**Business impact:** The vehicle is now available for sale again. Revenue KPIs do NOT change because revenue is calculated only on 'Signed' contracts. The contract still exists in the database for audit purposes — it is not deleted.

---

### 5.10 Attempt a Double Sale

**UI Location:** DB Features page → trg_PreventDoubleSale panel  
**What happens:**
```sql
-- This INSERT will FAIL if the VIN is already Sold
INSERT INTO SalesContracts (vin, customer_id, ...) VALUES ('JHMFC1F30MX000001', 2, ...);
```

**Result:** SQL Server raises an error:
```
The INSTEAD OF INSERT trigger trg_PreventDoubleSale blocked this operation.
Vehicle VIN 'JHMFC1F30MX000001' is already sold.
```

**Tables affected:** None — the INSERT is blocked. No data changes.  
**Why this matters:** Without this trigger, you could accidentally sell the same car twice. The trigger prevents this at the database level — no application code needed.

---

### 5.11 Start a Financing Plan

**UI Location:** Financing page → Add Plan sub-tab  
**SQL executed:**
```sql
INSERT INTO FinancingPlans (contract_id, bank_name, down_payment, tenure_months,
                            monthly_installment, interest_rate)
VALUES (1, 'HBL', 1000000, 36, 88000, 14.5);
```

**Tables affected:** FinancingPlans only (1 INSERT)  
**FK constraint:** `contract_id` must exist and be a Signed contract in SalesContracts  
**Downstream impact:** This contract now appears in:
- "Contracts with vs without financing" analytics
- "Bank financing the most contracts" analytics
- Customer profile (sp_CustomerProfile returns financing info)

---

### 5.12 Order Parts

**UI Location:** Parts Orders page → New Order sub-tab  
**SQL executed:**
```sql
INSERT INTO PartsOrders (dealership_id, part_name, part_number, quantity, unit_price, order_date, status)
VALUES (1, 'Brake Pad Set', 'HON-BRK-001', 10, 4500, '2024-07-01', 'Pending');
```

**Tables affected:** PartsOrders only (1 INSERT)  
**FK constraint:** `dealership_id` must exist in Dealerships  
**Downstream impact:** This order appears in:
- "Parts spend by dealership" analytics
- "Pending parts orders" on the dashboard
- Parts order queries by dealership/status

**Updating status later:**
```sql
UPDATE PartsOrders SET status = 'Dispatched' WHERE order_id = 1;
```
No triggers fire — status is just a tracking field. The dashboard's "Pending parts" KPI will decrease by 1.

---

### 5.13 Book a Service Appointment

**UI Location:** Service page → New Appointment sub-tab  
**SQL executed:**
```sql
INSERT INTO ServiceAppointments (customer_id, dealership_id, vin, appointment_date,
                                 service_type, status, technician_name)
VALUES (3, 2, 'JHMFC1F30MX000003', '2024-07-15', 'Full Service', 'Scheduled', 'Kamran Sheikh');
```

**Tables affected:** ServiceAppointments (1 INSERT)  
**FK constraints validated:**
- `customer_id` must exist in Customers
- `dealership_id` must exist in Dealerships
- `vin` must exist in Inventory

**Trigger impact:** None — there are no triggers on ServiceAppointments  
**Duplicate prevention (via sp_BookService):** If the same VIN + date combination already exists, the INSERT is blocked  
**Later updates:**
```sql
UPDATE ServiceAppointments SET status = 'Completed' WHERE appt_id = 1;
```
No triggers fire. The appointment moves from "Scheduled" to "Completed" for analytics tracking.

---

### 5.14 Run sp_RegisterSale (Atomic Sale)

**UI Location:** DB Features page → sp_RegisterSale panel  
**What it does internally (pseudocode):**
```
BEGIN TRANSACTION
  IF (Inventory.status != 'Available' WHERE vin = @vin)
    ROLLBACK
    RAISERROR 'Vehicle not available'
  
  INSERT INTO SalesContracts (vin, customer_id, dealership_id, ...,
                              status = 'Signed')
  
  UPDATE Inventory SET status = 'Sold' WHERE vin = @vin
  
  -- Note: The UPDATE Inventory also triggers trg_ContractSigned_UpdateInventory
  -- but since status is already 'Sold', it's a no-op
COMMIT
```

**Tables affected if successful:**
- SalesContracts (1 INSERT)
- Inventory (1 UPDATE — status changes to 'Sold')

**Tables affected if failure:**
- None — all changes are rolled back

**Why use a procedure instead of separate statements?**
Without the procedure, if the INSERT succeeds but the UPDATE fails, you have a contract for an unsold vehicle — data inconsistency. The procedure's transaction ensures both succeed or both fail.

---

### 5.15 Run sp_CustomerProfile

**UI Location:** DB Features page → sp_CustomerProfile panel  
**SQL executed:**
```sql
EXEC sp_CustomerProfile @customer_id = 1;
```

**Tables read:**
- Customers (WHERE customer_id = 1)
- SalesContracts (WHERE customer_id = 1)
- ServiceAppointments (WHERE customer_id = 1)

**Tables affected:** None (read-only)  
**What you get (3 result sets):**
```
Result Set 1: Customer info (name, phone, email, address, CNIC)
Result Set 2: All contracts with dates, prices, payment modes, statuses
Result Set 3: All service appointments with dates, types, statuses, technicians
```

---

### 5.16 Run sp_MonthlySalesReport

**UI Location:** DB Features page → sp_MonthlySalesReport panel  
**SQL executed:**
```sql
EXEC sp_MonthlySalesReport @dealership_id = 1, @year = 2024, @month = 6;
```

**Tables read:**
- SalesContracts (filtered by dealership, date range, status='Signed')
- Dealerships (for name/city display)

**Tables affected:** None (read-only)  
**What you get (2 result sets):**
```
Result Set 1: Detail — every signed contract that month (VIN, customer, date, price, net)
Result Set 2: Summary — total revenue, avg sale price, contract count
```

---

### 5.17 Run sp_BookService

**UI Location:** DB Features page → sp_BookService panel  
**What it does internally (pseudocode):**
```
BEGIN TRANSACTION
  IF EXISTS (SELECT 1 FROM ServiceAppointments
             WHERE vin = @vin AND appointment_date = @appointment_date
             AND status = 'Scheduled')
    ROLLBACK
    RAISERROR 'VIN already has a scheduled appointment on this date'
  
  INSERT INTO ServiceAppointments (...)
COMMIT
```

**Tables affected if successful:** ServiceAppointments (1 INSERT)  
**Tables affected if failure:** None (rollback)  
**Why this matters:** Without this check, you could double-book a vehicle at two different dealerships on the same day. The procedure prevents this.

---

## 6. Data Integrity Rules

These rules are enforced by the database structure — you cannot violate them through the UI or direct SQL.

### Rule 1: No Orphan Records
Every child record must have a valid parent.  
**Example:** You cannot insert a SalesContract with `customer_id = 999` if no customer with that ID exists.

### Rule 2: Status Values Are Restricted
Every status column has a CHECK constraint allowing only specific values:
| Table | Column | Allowed Values |
|-------|--------|----------------|
| Inventory | status | 'Available', 'Reserved', 'Sold', 'In Transit' |
| SalesContracts | status | 'Pending', 'Signed', 'Cancelled' |
| SalesContracts | payment_mode | 'Cash', 'Installment', 'Lease' |
| PartsOrders | status | 'Pending', 'Dispatched', 'Delivered' |
| ServiceAppointments | status | 'Scheduled', 'Completed', 'Cancelled' |
| ServiceAppointments | service_type | 'Oil Change', 'Full Service', 'Repair', 'Inspection' |
| VehicleModels | fuel_type | 'Petrol', 'Diesel', 'Hybrid', 'Electric' |

### Rule 3: One Vehicle, One Sale (at a time)
The trigger `trg_PreventDoubleSale` ensures a vehicle marked 'Sold' cannot be sold again. Combined with `trg_ContractCancelled_RestoreInventory`, a vehicle can only be re-sold after its previous contract is cancelled.

### Rule 4: Pending Reserves the Vehicle
The trigger `trg_ContractPending_ReserveInventory` ensures that once a Pending contract is created for a VIN, its status changes to 'Reserved'. No other customer can buy it until the contract either gets signed (→ Sold) or cancelled (→ Available).

### Rule 5: Atomic Sales
`sp_RegisterSale` wraps the entire sale process in a transaction. If any step fails (e.g., vehicle unavailable, database error), ALL changes are rolled back. No partial sales.

---

## 7. What Happens When You Violate a Rule

| Violation | Error You See | Why |
|-----------|--------------|-----|
| Insert contract with non-existent customer_id | `The INSERT statement conflicted with the FOREIGN KEY constraint "FK_SalesContracts_Customers"` | FK constraint prevents orphan contracts |
| Set Inventory.status = 'Flying' | `The INSERT statement conflicted with the CHECK constraint "CK_Inventory_Status"` | CHECK constraint restricts values |
| Insert a contract for an already-sold VIN | `trg_PreventDoubleSale blocked this operation. Vehicle VIN '...' is already sold.` | INSTEAD OF trigger blocks the insert |
| Book service for same VIN on same date (sp_BookService) | `VIN already has a scheduled appointment on this date` | Stored procedure checks for duplicates |
| Delete a customer who has contracts | `The DELETE statement conflicted with the REFERENCE constraint` | FK constraint prevents deleting customers with active contracts |
| Insert duplicate VIN | `Violation of PRIMARY KEY constraint 'PK_Inventory'` | PK enforces uniqueness |

---

## Quick Reference: Where to Find Things

| Question | Look in DATA_RELATIONSHIPS_AND_IMPACTS.md Section |
|----------|---------------------------------------------------|
| What tables are linked and how? | Section 2 — Foreign Key Map |
| What happens when I cancel a contract? | Section 5.9 + Section 3 |
| What triggers fire when I sign a contract? | Section 3 — Trigger Impact Map |
| How does a new plant affect the system? | Section 5.1 |
| Can I sell the same car twice? | Section 5.10 — it's blocked |
| What is an atomic sale? | Section 5.14 — sp_RegisterSale |
| How does booking service prevent duplicates? | Section 5.17 — sp_BookService |
| What status values are allowed? | Section 6 — Data Integrity Rules |
| What happens if I break a rule? | Section 7 — Violation Errors |
| How does one INSERT affect other tables? | Section 5 — Action Impact Catalog |
