/*
╔══════════════════════════════════════════════════════════════════════════════╗
║                     HONDA DMS — Full Database Setup                        ║
║  Honda Dealership Management System — 10 Tables, 4 Procedures,             ║
║  4 Triggers, 5 Views, 15 Indexes, Sample Data                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
Run this script in SSMS (or sqlcmd) against a database named `honda_dms`.

Usage:
  1. CREATE DATABASE honda_dms;
  2. USE honda_dms;
  3. Execute this script
  4. Update the connection string in api.py to match your server
*/

-- ============================================================================
-- DATABASE CONTEXT
-- ============================================================================
IF DB_ID('honda_dms') IS NULL
BEGIN
    CREATE DATABASE honda_dms;
END
GO
USE honda_dms;
GO

-- ============================================================================
-- 1. TABLES (10)
-- ============================================================================

-- 1.1 Plants
IF OBJECT_ID('dbo.Plants', 'U') IS NOT NULL DROP TABLE dbo.Plants;
CREATE TABLE dbo.Plants (
    plant_id        INT           IDENTITY(1,1) NOT NULL,
    plant_name      NVARCHAR(100) NOT NULL,
    country         NVARCHAR(50)  NOT NULL,
    city            NVARCHAR(50)  NOT NULL,
    annual_capacity INT           NOT NULL,
    CONSTRAINT PK_Plants PRIMARY KEY (plant_id)
);

-- 1.2 VehicleModels
IF OBJECT_ID('dbo.VehicleModels', 'U') IS NOT NULL DROP TABLE dbo.VehicleModels;
CREATE TABLE dbo.VehicleModels (
    model_id      INT            IDENTITY(1,1) NOT NULL,
    model_name    NVARCHAR(100)  NOT NULL,
    category      NVARCHAR(50)   NOT NULL,
    engine_cc     INT            NOT NULL,
    fuel_type     NVARCHAR(20)   NOT NULL,
    transmission  NVARCHAR(20)   NOT NULL,
    base_price    DECIMAL(12, 2) NOT NULL,
    CONSTRAINT PK_VehicleModels PRIMARY KEY (model_id),
    CONSTRAINT CK_VehicleModels_FuelType
        CHECK (fuel_type IN (N'Petrol', N'Diesel', N'Hybrid', N'Electric'))
);

-- 1.3 ProductionBatches
IF OBJECT_ID('dbo.ProductionBatches', 'U') IS NOT NULL DROP TABLE dbo.ProductionBatches;
CREATE TABLE dbo.ProductionBatches (
    batch_id       INT  IDENTITY(1,1) NOT NULL,
    plant_id       INT  NOT NULL,
    model_id       INT  NOT NULL,
    batch_date     DATE NOT NULL,
    units_produced INT  NOT NULL,
    dispatch_date  DATE NULL,
    CONSTRAINT PK_ProductionBatches PRIMARY KEY (batch_id)
);

-- 1.4 Dealerships
IF OBJECT_ID('dbo.Dealerships', 'U') IS NOT NULL DROP TABLE dbo.Dealerships;
CREATE TABLE dbo.Dealerships (
    dealership_id   INT           IDENTITY(1,1) NOT NULL,
    dealership_name NVARCHAR(100) NOT NULL,
    city            NVARCHAR(50)  NOT NULL,
    region          NVARCHAR(20)  NOT NULL,
    contact_phone   NVARCHAR(20)  NULL,
    manager_name    NVARCHAR(100) NULL,
    CONSTRAINT PK_Dealerships PRIMARY KEY (dealership_id)
);

-- 1.5 Inventory
IF OBJECT_ID('dbo.Inventory', 'U') IS NOT NULL DROP TABLE dbo.Inventory;
CREATE TABLE dbo.Inventory (
    vin            NVARCHAR(17)  NOT NULL,
    dealership_id  INT           NOT NULL,
    model_id       INT           NOT NULL,
    color          NVARCHAR(30)  NOT NULL,
    year           INT           NOT NULL,
    status         NVARCHAR(20)  NOT NULL,
    arrival_date   DATE          NOT NULL,
    CONSTRAINT PK_Inventory PRIMARY KEY (vin),
    CONSTRAINT CK_Inventory_Status
        CHECK (status IN (N'Available', N'Reserved', N'Sold', N'In Transit'))
);

-- 1.6 Customers
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;
CREATE TABLE dbo.Customers (
    customer_id INT           IDENTITY(1,1) NOT NULL,
    full_name   NVARCHAR(100) NOT NULL,
    phone       NVARCHAR(20)  NULL,
    email       NVARCHAR(100) NULL,
    address     NVARCHAR(200) NULL,
    cnic        NVARCHAR(20)  NULL,
    CONSTRAINT PK_Customers PRIMARY KEY (customer_id)
);

-- 1.7 SalesContracts
IF OBJECT_ID('dbo.SalesContracts', 'U') IS NOT NULL DROP TABLE dbo.SalesContracts;
CREATE TABLE dbo.SalesContracts (
    contract_id    INT            IDENTITY(1,1) NOT NULL,
    vin            NVARCHAR(17)   NOT NULL,
    customer_id    INT            NOT NULL,
    dealership_id  INT            NOT NULL,
    contract_date  DATE           NOT NULL,
    agreed_price   DECIMAL(12, 2) NOT NULL,
    discount       DECIMAL(12, 2) NOT NULL DEFAULT 0,
    tax            DECIMAL(12, 2) NOT NULL DEFAULT 0,
    payment_mode   NVARCHAR(20)   NOT NULL,
    status         NVARCHAR(20)   NOT NULL,
    CONSTRAINT PK_SalesContracts PRIMARY KEY (contract_id),
    CONSTRAINT CK_SalesContracts_Status
        CHECK (status IN (N'Pending', N'Signed', N'Cancelled')),
    CONSTRAINT CK_SalesContracts_PaymentMode
        CHECK (payment_mode IN (N'Cash', N'Installment', N'Lease'))
);

-- 1.8 FinancingPlans
IF OBJECT_ID('dbo.FinancingPlans', 'U') IS NOT NULL DROP TABLE dbo.FinancingPlans;
CREATE TABLE dbo.FinancingPlans (
    financing_id       INT            IDENTITY(1,1) NOT NULL,
    contract_id        INT            NOT NULL,
    bank_name          NVARCHAR(100)  NOT NULL,
    down_payment       DECIMAL(12, 2) NOT NULL,
    tenure_months      INT            NOT NULL,
    monthly_installment DECIMAL(12, 2) NOT NULL,
    interest_rate      DECIMAL(5, 2)  NOT NULL,
    CONSTRAINT PK_FinancingPlans PRIMARY KEY (financing_id)
);

-- 1.9 PartsOrders
IF OBJECT_ID('dbo.PartsOrders', 'U') IS NOT NULL DROP TABLE dbo.PartsOrders;
CREATE TABLE dbo.PartsOrders (
    order_id      INT            IDENTITY(1,1) NOT NULL,
    dealership_id INT            NOT NULL,
    part_name     NVARCHAR(100)  NOT NULL,
    part_number   NVARCHAR(50)   NOT NULL,
    quantity      INT            NOT NULL,
    unit_price    DECIMAL(10, 2) NOT NULL,
    order_date    DATE           NOT NULL,
    status        NVARCHAR(20)   NOT NULL,
    CONSTRAINT PK_PartsOrders PRIMARY KEY (order_id),
    CONSTRAINT CK_PartsOrders_Status
        CHECK (status IN (N'Pending', N'Dispatched', N'Delivered'))
);

-- 1.10 ServiceAppointments
IF OBJECT_ID('dbo.ServiceAppointments', 'U') IS NOT NULL DROP TABLE dbo.ServiceAppointments;
CREATE TABLE dbo.ServiceAppointments (
    appt_id          INT           IDENTITY(1,1) NOT NULL,
    customer_id      INT           NOT NULL,
    dealership_id    INT           NOT NULL,
    vin              NVARCHAR(17)  NOT NULL,
    appointment_date DATE          NOT NULL,
    service_type     NVARCHAR(30)  NOT NULL,
    status           NVARCHAR(20)  NOT NULL,
    technician_name  NVARCHAR(100) NULL,
    CONSTRAINT PK_ServiceAppointments PRIMARY KEY (appt_id),
    CONSTRAINT CK_ServiceAppointments_ServiceType
        CHECK (service_type IN (N'Oil Change', N'Full Service', N'Repair', N'Inspection')),
    CONSTRAINT CK_ServiceAppointments_Status
        CHECK (status IN (N'Scheduled', N'Completed', N'Cancelled'))
);

-- ============================================================================
-- 2. FOREIGN KEY CONSTRAINTS (12)
-- ============================================================================

-- ProductionBatches
ALTER TABLE dbo.ProductionBatches ADD CONSTRAINT FK_ProductionBatches_Plants
    FOREIGN KEY (plant_id) REFERENCES dbo.Plants(plant_id);
ALTER TABLE dbo.ProductionBatches ADD CONSTRAINT FK_ProductionBatches_VehicleModels
    FOREIGN KEY (model_id) REFERENCES dbo.VehicleModels(model_id);

-- Inventory
ALTER TABLE dbo.Inventory ADD CONSTRAINT FK_Inventory_Dealerships
    FOREIGN KEY (dealership_id) REFERENCES dbo.Dealerships(dealership_id);
ALTER TABLE dbo.Inventory ADD CONSTRAINT FK_Inventory_VehicleModels
    FOREIGN KEY (model_id) REFERENCES dbo.VehicleModels(model_id);

-- SalesContracts
ALTER TABLE dbo.SalesContracts ADD CONSTRAINT FK_SalesContracts_Inventory
    FOREIGN KEY (vin) REFERENCES dbo.Inventory(vin);
ALTER TABLE dbo.SalesContracts ADD CONSTRAINT FK_SalesContracts_Customers
    FOREIGN KEY (customer_id) REFERENCES dbo.Customers(customer_id);
ALTER TABLE dbo.SalesContracts ADD CONSTRAINT FK_SalesContracts_Dealerships
    FOREIGN KEY (dealership_id) REFERENCES dbo.Dealerships(dealership_id);

-- FinancingPlans
ALTER TABLE dbo.FinancingPlans ADD CONSTRAINT FK_FinancingPlans_SalesContracts
    FOREIGN KEY (contract_id) REFERENCES dbo.SalesContracts(contract_id);

-- PartsOrders
ALTER TABLE dbo.PartsOrders ADD CONSTRAINT FK_PartsOrders_Dealerships
    FOREIGN KEY (dealership_id) REFERENCES dbo.Dealerships(dealership_id);

-- ServiceAppointments
ALTER TABLE dbo.ServiceAppointments ADD CONSTRAINT FK_ServiceAppointments_Customers
    FOREIGN KEY (customer_id) REFERENCES dbo.Customers(customer_id);
ALTER TABLE dbo.ServiceAppointments ADD CONSTRAINT FK_ServiceAppointments_Dealerships
    FOREIGN KEY (dealership_id) REFERENCES dbo.Dealerships(dealership_id);
ALTER TABLE dbo.ServiceAppointments ADD CONSTRAINT FK_ServiceAppointments_Inventory
    FOREIGN KEY (vin) REFERENCES dbo.Inventory(vin);

-- ============================================================================
-- 3. INDEXES (15)
-- ============================================================================

-- Inventory
CREATE INDEX IX_Inventory_Status        ON dbo.Inventory(status);
CREATE INDEX IX_Inventory_ModelID       ON dbo.Inventory(model_id);
CREATE INDEX IX_Inventory_DealershipID  ON dbo.Inventory(dealership_id);
CREATE INDEX IX_Inventory_ArrivalDate   ON dbo.Inventory(arrival_date);

-- SalesContracts
CREATE INDEX IX_SalesContracts_Status       ON dbo.SalesContracts(status);
CREATE INDEX IX_SalesContracts_CustomerID   ON dbo.SalesContracts(customer_id);
CREATE INDEX IX_SalesContracts_DealershipID ON dbo.SalesContracts(dealership_id);
CREATE INDEX IX_SalesContracts_VIN          ON dbo.SalesContracts(vin);
CREATE INDEX IX_SalesContracts_ContractDate ON dbo.SalesContracts(contract_date);

-- ProductionBatches
CREATE INDEX IX_ProductionBatches_PlantID ON dbo.ProductionBatches(plant_id);
CREATE INDEX IX_ProductionBatches_ModelID ON dbo.ProductionBatches(model_id);
CREATE INDEX IX_ProductionBatches_Date    ON dbo.ProductionBatches(batch_date);

-- PartsOrders
CREATE INDEX IX_PartsOrders_DealershipID ON dbo.PartsOrders(dealership_id);
CREATE INDEX IX_PartsOrders_Status       ON dbo.PartsOrders(status);

-- ServiceAppointments
CREATE INDEX IX_ServiceAppointments_CustomerID   ON dbo.ServiceAppointments(customer_id);
CREATE INDEX IX_ServiceAppointments_DealershipID ON dbo.ServiceAppointments(dealership_id);
CREATE INDEX IX_ServiceAppointments_VIN          ON dbo.ServiceAppointments(vin);
CREATE INDEX IX_ServiceAppointments_Status       ON dbo.ServiceAppointments(status);

-- ============================================================================
-- 4. STORED PROCEDURES (4)
-- ============================================================================

-- 4.1 sp_RegisterSale — Atomic sale transaction
GO
IF OBJECT_ID('dbo.sp_RegisterSale', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_RegisterSale;
GO
CREATE PROCEDURE dbo.sp_RegisterSale
    @vin             NVARCHAR(17),
    @customer_id     INT,
    @dealership_id   INT,
    @agreed_price    DECIMAL(12,2),
    @discount        DECIMAL(12,2) = 0,
    @tax             DECIMAL(12,2) = 0,
    @payment_mode    NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validate vehicle is available
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Inventory
            WHERE vin = @vin AND status = N'Available'
        )
        BEGIN
            RAISERROR(N'Vehicle VIN %s is not available for sale.', 16, 1, @vin);
            ROLLBACK;
            RETURN;
        END;

        -- Insert signed contract
        INSERT INTO dbo.SalesContracts
            (vin, customer_id, dealership_id, contract_date,
             agreed_price, discount, tax, payment_mode, status)
        VALUES
            (@vin, @customer_id, @dealership_id, GETDATE(),
             @agreed_price, @discount, @tax, @payment_mode, N'Signed');

        -- Update inventory to Sold
        UPDATE dbo.Inventory SET status = N'Sold' WHERE vin = @vin;

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH;
END;
GO

-- 4.2 sp_CustomerProfile — Multi-result-set profile
GO
IF OBJECT_ID('dbo.sp_CustomerProfile', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_CustomerProfile;
GO
CREATE PROCEDURE dbo.sp_CustomerProfile
    @customer_id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Result set 1: Customer info
    SELECT customer_id, full_name, phone, email, address, cnic
    FROM dbo.Customers
    WHERE customer_id = @customer_id;

    -- Result set 2: Sales contracts
    SELECT sc.contract_id, sc.vin, d.dealership_name, sc.contract_date,
           sc.agreed_price, sc.discount, sc.tax,
           (sc.agreed_price - sc.discount + sc.tax) AS net_amount,
           sc.payment_mode, sc.status
    FROM dbo.SalesContracts sc
    JOIN dbo.Dealerships d ON sc.dealership_id = d.dealership_id
    WHERE sc.customer_id = @customer_id
    ORDER BY sc.contract_date DESC;

    -- Result set 3: Service history
    SELECT sa.appt_id, sa.vin, d.dealership_name, sa.appointment_date,
           sa.service_type, sa.status, sa.technician_name
    FROM dbo.ServiceAppointments sa
    JOIN dbo.Dealerships d ON sa.dealership_id = d.dealership_id
    WHERE sa.customer_id = @customer_id
    ORDER BY sa.appointment_date DESC;
END;
GO

-- 4.3 sp_MonthlySalesReport — Revenue breakdown
GO
IF OBJECT_ID('dbo.sp_MonthlySalesReport', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_MonthlySalesReport;
GO
CREATE PROCEDURE dbo.sp_MonthlySalesReport
    @dealership_id INT,
    @year          INT,
    @month         INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Result set 1: Detail
    SELECT sc.contract_id, sc.vin, c.full_name AS customer,
           sc.contract_date, sc.agreed_price, sc.discount, sc.tax,
           (sc.agreed_price - sc.discount + sc.tax) AS net_amount,
           sc.payment_mode
    FROM dbo.SalesContracts sc
    JOIN dbo.Customers c ON sc.customer_id = c.customer_id
    WHERE sc.dealership_id = @dealership_id
      AND YEAR(sc.contract_date) = @year
      AND MONTH(sc.contract_date) = @month
      AND sc.status = N'Signed'
    ORDER BY sc.contract_date;

    -- Result set 2: Summary
    SELECT COUNT(*)              AS total_contracts,
           SUM(sc.agreed_price - sc.discount + sc.tax) AS total_revenue,
           AVG(sc.agreed_price)  AS avg_sale_price,
           d.dealership_name,
           d.city
    FROM dbo.SalesContracts sc
    JOIN dbo.Dealerships d ON sc.dealership_id = d.dealership_id
    WHERE sc.dealership_id = @dealership_id
      AND YEAR(sc.contract_date) = @year
      AND MONTH(sc.contract_date) = @month
      AND sc.status = N'Signed'
    GROUP BY d.dealership_id, d.dealership_name, d.city;
END;
GO

-- 4.4 sp_BookService — Duplicate-guarded appointment booking
GO
IF OBJECT_ID('dbo.sp_BookService', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_BookService;
GO
CREATE PROCEDURE dbo.sp_BookService
    @customer_id      INT,
    @dealership_id    INT,
    @vin              NVARCHAR(17),
    @appointment_date DATE,
    @service_type     NVARCHAR(30),
    @technician_name  NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Check for duplicate booking: same VIN + same date + still Scheduled
        IF EXISTS (
            SELECT 1 FROM dbo.ServiceAppointments
            WHERE vin = @vin
              AND appointment_date = @appointment_date
              AND status = N'Scheduled'
        )
        BEGIN
            RAISERROR(N'VIN %s already has a scheduled appointment on %s.', 16, 1, @vin, @appointment_date);
            ROLLBACK;
            RETURN;
        END;

        INSERT INTO dbo.ServiceAppointments
            (customer_id, dealership_id, vin, appointment_date,
             service_type, status, technician_name)
        VALUES
            (@customer_id, @dealership_id, @vin, @appointment_date,
             @service_type, N'Scheduled', @technician_name);

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH;
END;
GO

-- ============================================================================
-- 5. TRIGGERS (4)
-- ============================================================================

-- 5.1 trg_ContractSigned_UpdateInventory
-- AFTER INSERT, UPDATE: when status becomes 'Signed', mark inventory as 'Sold'
GO
IF OBJECT_ID('dbo.trg_ContractSigned_UpdateInventory', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_ContractSigned_UpdateInventory;
GO
CREATE TRIGGER dbo.trg_ContractSigned_UpdateInventory
ON dbo.SalesContracts
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE i
    SET i.status = N'Sold'
    FROM dbo.Inventory i
    INNER JOIN inserted ins ON i.vin = ins.vin
    WHERE ins.status = N'Signed';
END;
GO

-- 5.2 trg_PreventDoubleSale
-- INSTEAD OF INSERT: block inserting a contract for a VIN that is already Sold
GO
IF OBJECT_ID('dbo.trg_PreventDoubleSale', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_PreventDoubleSale;
GO
CREATE TRIGGER dbo.trg_PreventDoubleSale
ON dbo.SalesContracts
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @vin NVARCHAR(17);

    SELECT @vin = i.vin
    FROM inserted i
    JOIN dbo.Inventory inv ON i.vin = inv.vin
    WHERE inv.status = N'Sold';

    IF @vin IS NOT NULL
    BEGIN
        RAISERROR(N'trg_PreventDoubleSale blocked this operation. Vehicle VIN %s is already sold.', 16, 1, @vin);
        ROLLBACK;
        RETURN;
    END;

    -- Allow the insert
    INSERT INTO dbo.SalesContracts
        (vin, customer_id, dealership_id, contract_date,
         agreed_price, discount, tax, payment_mode, status)
    SELECT vin, customer_id, dealership_id, contract_date,
           agreed_price, discount, tax, payment_mode, status
    FROM inserted;
END;
GO

-- 5.3 trg_ContractCancelled_RestoreInventory
-- AFTER UPDATE: when status becomes 'Cancelled', restore inventory to 'Available'
GO
IF OBJECT_ID('dbo.trg_ContractCancelled_RestoreInventory', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_ContractCancelled_RestoreInventory;
GO
CREATE TRIGGER dbo.trg_ContractCancelled_RestoreInventory
ON dbo.SalesContracts
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE i
    SET i.status = N'Available'
    FROM dbo.Inventory i
    INNER JOIN inserted ins ON i.vin = ins.vin
    WHERE ins.status = N'Cancelled';
END;
GO

-- 5.4 trg_ContractPending_ReserveInventory
-- AFTER INSERT: when a Pending contract is inserted, reserve the vehicle
GO
IF OBJECT_ID('dbo.trg_ContractPending_ReserveInventory', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_ContractPending_ReserveInventory;
GO
CREATE TRIGGER dbo.trg_ContractPending_ReserveInventory
ON dbo.SalesContracts
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE i
    SET i.status = N'Reserved'
    FROM dbo.Inventory i
    INNER JOIN inserted ins ON i.vin = ins.vin
    WHERE ins.status = N'Pending';
END;
GO

-- ============================================================================
-- 6. VIEWS (5)
-- ============================================================================

-- 6.1 vw_InventoryFull — Every inventory record with names
GO
IF OBJECT_ID('dbo.vw_InventoryFull', 'V') IS NOT NULL DROP VIEW dbo.vw_InventoryFull;
GO
CREATE VIEW dbo.vw_InventoryFull
AS
SELECT
    i.vin,
    d.dealership_name,
    d.city               AS dealership_city,
    vm.model_name,
    vm.category,
    i.color,
    i.year,
    i.status,
    i.arrival_date
FROM dbo.Inventory i
JOIN dbo.Dealerships d   ON i.dealership_id = d.dealership_id
JOIN dbo.VehicleModels vm ON i.model_id = vm.model_id;
GO

-- 6.2 vw_SignedContracts — All completed sales with net amount
GO
IF OBJECT_ID('dbo.vw_SignedContracts', 'V') IS NOT NULL DROP VIEW dbo.vw_SignedContracts;
GO
CREATE VIEW dbo.vw_SignedContracts
AS
SELECT
    sc.contract_id,
    sc.vin,
    c.full_name          AS customer,
    d.dealership_name,
    sc.contract_date,
    sc.agreed_price,
    sc.discount,
    sc.tax,
    (sc.agreed_price - sc.discount + sc.tax) AS net_amount,
    sc.payment_mode
FROM dbo.SalesContracts sc
JOIN dbo.Customers c     ON sc.customer_id = c.customer_id
JOIN dbo.Dealerships d   ON sc.dealership_id = d.dealership_id
WHERE sc.status = N'Signed';
GO

-- 6.3 vw_DealershipRevenue — Revenue per dealership
GO
IF OBJECT_ID('dbo.vw_DealershipRevenue', 'V') IS NOT NULL DROP VIEW dbo.vw_DealershipRevenue;
GO
CREATE VIEW dbo.vw_DealershipRevenue
AS
SELECT
    d.dealership_id,
    d.dealership_name,
    d.city,
    d.region,
    COUNT(sc.contract_id)            AS signed_contracts,
    ISNULL(SUM(sc.agreed_price - sc.discount + sc.tax), 0) AS total_revenue,
    ISNULL(AVG(sc.agreed_price), 0)  AS avg_sale_price
FROM dbo.Dealerships d
LEFT JOIN dbo.SalesContracts sc
    ON d.dealership_id = sc.dealership_id AND sc.status = N'Signed'
GROUP BY d.dealership_id, d.dealership_name, d.city, d.region;
GO

-- 6.4 vw_AvailableStock — Available units per model
GO
IF OBJECT_ID('dbo.vw_AvailableStock', 'V') IS NOT NULL DROP VIEW dbo.vw_AvailableStock;
GO
CREATE VIEW dbo.vw_AvailableStock
AS
SELECT
    vm.model_id,
    vm.model_name,
    vm.category,
    COUNT(i.vin)          AS available_units,
    vm.base_price
FROM dbo.VehicleModels vm
LEFT JOIN dbo.Inventory i
    ON vm.model_id = i.model_id AND i.status = N'Available'
GROUP BY vm.model_id, vm.model_name, vm.category, vm.base_price;
GO

-- 6.5 vw_ServiceHistory — Full service log per VIN
GO
IF OBJECT_ID('dbo.vw_ServiceHistory', 'V') IS NOT NULL DROP VIEW dbo.vw_ServiceHistory;
GO
CREATE VIEW dbo.vw_ServiceHistory
AS
SELECT
    sa.appt_id,
    sa.vin,
    vm.model_name,
    c.full_name           AS customer,
    c.phone               AS customer_phone,
    d.dealership_name,
    d.city                AS dealership_city,
    sa.appointment_date,
    sa.service_type,
    sa.status,
    sa.technician_name
FROM dbo.ServiceAppointments sa
JOIN dbo.Inventory i      ON sa.vin = i.vin
JOIN dbo.VehicleModels vm ON i.model_id = vm.model_id
JOIN dbo.Customers c      ON sa.customer_id = c.customer_id
JOIN dbo.Dealerships d    ON sa.dealership_id = d.dealership_id;
GO

-- ============================================================================
-- 7. SAMPLE DATA
-- ============================================================================

-- 7.1 Plants
SET IDENTITY_INSERT dbo.Plants ON;
INSERT INTO dbo.Plants (plant_id, plant_name, country, city, annual_capacity)
VALUES
    (1, N'Honda Lahore Plant',       N'Pakistan', N'Lahore',   50000),
    (2, N'Honda Karachi Plant',      N'Pakistan', N'Karachi',  35000),
    (3, N'Honda Islamabad Plant',    N'Pakistan', N'Islamabad', 25000),
    (4, N'Honda Tokyo Plant',        N'Japan',    N'Tokyo',    120000),
    (5, N'Honda Gujarat Plant',      N'India',    N'Gujarat',   80000);
SET IDENTITY_INSERT dbo.Plants OFF;

-- 7.2 VehicleModels
SET IDENTITY_INSERT dbo.VehicleModels ON;
INSERT INTO dbo.VehicleModels (model_id, model_name, category, engine_cc, fuel_type, transmission, base_price)
VALUES
    (1, N'Civic 1.8',        N'Sedan',   1799, N'Petrol',  N'Automatic', 3800000),
    (2, N'Civic RS',         N'Sedan',   1498, N'Petrol',  N'CVT',       4400000),
    (3, N'City 1.5',         N'Sedan',   1497, N'Petrol',  N'CVT',       3200000),
    (4, N'BR-V',             N'SUV',     1497, N'Petrol',  N'CVT',       3600000),
    (5, N'HR-V',             N'SUV',     1498, N'Petrol',  N'CVT',       4200000),
    (6, N'CR-V',             N'SUV',     1996, N'Petrol',  N'CVT',       6500000),
    (7, N'Accord Hybrid',    N'Sedan',   1993, N'Hybrid',  N'CVT',       8500000),
    (8, N'Civic 1.8 Diesel',N'Sedan',   1799, N'Diesel',  N'Manual',    4000000),
    (9, N'Vezel Hybrid',     N'SUV',     1496, N'Hybrid',  N'CVT',       5500000),
    (10, N'Civic Type R',    N'Hatchback', 1996, N'Petrol', N'Manual',   9500000);
SET IDENTITY_INSERT dbo.VehicleModels OFF;

-- 7.3 ProductionBatches
SET IDENTITY_INSERT dbo.ProductionBatches ON;
INSERT INTO dbo.ProductionBatches (batch_id, plant_id, model_id, batch_date, units_produced, dispatch_date)
VALUES
    (1, 1, 1, '2024-01-15', 100, '2024-02-01'),
    (2, 1, 3, '2024-01-20', 80,  '2024-02-05'),
    (3, 2, 4, '2024-02-01', 60,  '2024-02-20'),
    (4, 1, 2, '2024-02-10', 50,  '2024-03-01'),
    (5, 3, 6, '2024-02-15', 30,  '2024-03-05'),
    (6, 2, 5, '2024-03-01', 40,  '2024-03-20'),
    (7, 1, 7, '2024-03-10', 25,  '2024-04-01'),
    (8, 3, 1, '2024-03-15', 70,  '2024-04-05'),
    (9, 2, 8, '2024-04-01', 35,  '2024-04-20'),
    (10, 1, 9, '2024-04-10', 20,  '2024-05-01');
SET IDENTITY_INSERT dbo.ProductionBatches OFF;

-- 7.4 Dealerships
SET IDENTITY_INSERT dbo.Dealerships ON;
INSERT INTO dbo.Dealerships (dealership_id, dealership_name, city, region, contact_phone, manager_name)
VALUES
    (1, N'Honda Atlas — Lahore',     N'Lahore',    N'North', N'042-111-1234', N'Ahmad Khan'),
    (2, N'Honda Atlas — Karachi',    N'Karachi',   N'South', N'021-111-5678', N'Farhan Ali'),
    (3, N'Honda Capital — Islamabad', N'Islamabad', N'North', N'051-111-9012', N'Usman Malik'),
    (4, N'Honda Garden — Faisalabad', N'Faisalabad',N'Central', N'041-111-3456', N'Bilal Ahmed'),
    (5, N'Honda Pearl — Rawalpindi',  N'Rawalpindi',N'North', N'051-111-7890', N'Kamran Sheikh');
SET IDENTITY_INSERT dbo.Dealerships OFF;

-- 7.5 Inventory
INSERT INTO dbo.Inventory (vin, dealership_id, model_id, color, year, status, arrival_date)
VALUES
    (N'JHMF C1F30MX000001', 1, 1, N'White Pearl',      2024, N'Available',  '2024-02-01'),
    (N'JHMF C1F30MX000002', 1, 1, N'Black Obsidian',   2024, N'Sold',       '2024-02-01'),
    (N'JHMF C1F30MX000003', 1, 3, N'Modern Steel',     2024, N'Available',  '2024-02-05'),
    (N'JHMF C1F30MX000004', 2, 4, N'Golden Brown',     2024, N'Available',  '2024-02-20'),
    (N'JHMF C1F30MX000005', 2, 4, N'White Pearl',      2024, N'Sold',       '2024-02-20'),
    (N'JHMF C1F30MX000006', 1, 2, N'Rallye Red',       2024, N'Available',  '2024-03-01'),
    (N'JHMF C1F30MX000007', 3, 6, N'Lunar Silver',     2024, N'Available',  '2024-03-05'),
    (N'JHMF C1F30MX000008', 2, 5, N'Platinum White',   2024, N'Sold',       '2024-03-20'),
    (N'JHMF C1F30MX000009', 1, 7, N'Crystal Black',    2024, N'Available',  '2024-04-01'),
    (N'JHMF C1F30MX000010', 3, 1, N'White Pearl',      2024, N'Available',  '2024-04-05'),
    (N'JHMF C1F30MX000011', 2, 8, N'Deep Ocean Blue',  2024, N'Available',  '2024-04-20'),
    (N'JHMF C1F30MX000012', 1, 9, N'Premium Red',      2024, N'Available',  '2024-05-01'),
    (N'JHMF C1F30MX000013', 4, 3, N'Modern Steel',     2024, N'In Transit', '2024-05-10'),
    (N'JHMF C1F30MX000014', 5, 2, N'Rallye Red',       2024, N'Available',  '2024-05-12'),
    (N'JHMF C1F30MX000015', 4, 6, N'Lunar Silver',     2024, N'Available',  '2024-05-15'),
    (N'JHMF C1F30MX000016', 1, 4, N'Golden Brown',     2024, N'Reserved',   '2024-05-20'),
    (N'JHMF C1F30MX000017', 3, 5, N'Platinum White',   2024, N'Available',  '2024-06-01'),
    (N'JHMF C1F30MX000018', 2, 1, N'Black Obsidian',   2024, N'Available',  '2024-06-05'),
    (N'JHMF C1F30MX000019', 5, 7, N'Crystal Black',    2024, N'Available',  '2024-06-10'),
    (N'JHMF C1F30MX000020', 4, 9, N'Sonic Gray',       2024, N'Available',  '2024-06-15');

-- 7.6 Customers
SET IDENTITY_INSERT dbo.Customers ON;
INSERT INTO dbo.Customers (customer_id, full_name, phone, email, address, cnic)
VALUES
    (1, N'Ali Raza',        N'0300-1234567', N'ali@email.com',     N'House 12, DHA Phase 5, Lahore',        N'35202-1234567-1'),
    (2, N'Sana Fatima',     N'0321-7654321', N'sana@email.com',    N'Flat 3B, Clifton, Karachi',            N'42101-7654321-2'),
    (3, N'Usman Chaudhry',  N'0333-5556667', N'usman@email.com',   N'Street 7, G-11/4, Islamabad',           N'61101-5556667-3'),
    (4, N'Fatima Ali',      N'0345-8889990', N'fatima@email.com',  N'45-A, Gulberg III, Lahore',             N'35201-8889990-4'),
    (5, N'Hassan Nawaz',    N'0301-4445556', N'hassan@email.com',  N'12-K, Model Town, Faisalabad',          N'33100-4445556-5'),
    (6, N'Zara Malik',      N'0336-7778889', N'zara@email.com',    N'Villa 8, Defence, Karachi',             N'42101-7778889-6'),
    (7, N'Omar Farooq',     N'0312-2223334', N'omar@email.com',    N'House 3, University Road, Rawalpindi',  N'37301-2223334-7'),
    (8, N'Hina Tariq',      N'0302-1112223', N'hina@email.com',    N'13-C, Canal Bank, Lahore',              N'35202-1112223-8'),
    (9, N'Bilal Sheikh',    N'0341-6667778', N'bilal@email.com',   N'Flat 7, Blue Area, Islamabad',          N'61101-6667778-9'),
    (10, N'Rabia Anwar',    N'0315-3334445', N'rabia@email.com',   N'55-B, Peoples Colony, Faisalabad',      N'33100-3334445-0');
SET IDENTITY_INSERT dbo.Customers OFF;

-- 7.7 SalesContracts
SET IDENTITY_INSERT dbo.SalesContracts ON;
INSERT INTO dbo.SalesContracts (contract_id, vin, customer_id, dealership_id, contract_date, agreed_price, discount, tax, payment_mode, status)
VALUES
    (1, N'JHMF C1F30MX000002', 1, 1, '2024-03-01', 4200000, 50000,  210000, N'Cash',        N'Signed'),
    (2, N'JHMF C1F30MX000005', 2, 2, '2024-03-15', 3800000, 80000,  190000, N'Installment', N'Signed'),
    (3, N'JHMF C1F30MX000008', 4, 2, '2024-04-05', 4600000, 100000, 230000, N'Lease',       N'Signed'),
    (4, N'JHMF C1F30MX000001', 3, 1, '2024-04-10', 4000000, 50000,  200000, N'Cash',        N'Pending'),
    (5, N'JHMF C1F30MX000016', 6, 1, '2024-05-22', 3800000, 60000,  190000, N'Installment', N'Pending'),
    (6, N'JHMF C1F30MX000003', 5, 1, '2024-05-25', 3500000, 40000,  175000, N'Cash',        N'Pending');
SET IDENTITY_INSERT dbo.SalesContracts OFF;

-- 7.8 FinancingPlans
SET IDENTITY_INSERT dbo.FinancingPlans ON;
INSERT INTO dbo.FinancingPlans (financing_id, contract_id, bank_name, down_payment, tenure_months, monthly_installment, interest_rate)
VALUES
    (1, 2, N'HBL',        1000000, 36, 88000,  14.5),
    (2, 3, N'UBL',        1500000, 24, 138000, 13.0),
    (3, 5, N'Bank Alfalah', 800000, 48, 75000, 15.0);
SET IDENTITY_INSERT dbo.FinancingPlans OFF;

-- 7.9 PartsOrders
SET IDENTITY_INSERT dbo.PartsOrders ON;
INSERT INTO dbo.PartsOrders (order_id, dealership_id, part_name, part_number, quantity, unit_price, order_date, status)
VALUES
    (1, 1, N'Brake Pad Set',         N'HON-BRK-001', 10, 4500,   '2024-06-01', N'Dispatched'),
    (2, 2, N'Oil Filter',            N'HON-OIL-002', 20, 1200,   '2024-06-02', N'Pending'),
    (3, 1, N'Engine Oil 5W-30',      N'HON-ENG-003', 30, 3500,   '2024-06-05', N'Pending'),
    (4, 3, N'Air Filter',            N'HON-AIR-004', 15, 1800,   '2024-06-08', N'Pending'),
    (5, 2, N'Spark Plug Set',        N'HON-SPK-005', 12, 2500,   '2024-06-10', N'Delivered'),
    (6, 4, N'Transmission Fluid',    N'HON-TRN-006', 8,  5500,   '2024-06-12', N'Pending'),
    (7, 1, N'Coolant 5L',            N'HON-CLN-007', 10, 2200,   '2024-06-15', N'Pending'),
    (8, 5, N'Brake Fluid',           N'HON-BRF-008', 10, 1500,   '2024-06-18', N'Pending'),
    (9, 3, N'Wiper Blade Set',       N'HON-WIP-009', 20, 1800,   '2024-06-20', N'Dispatched'),
    (10, 2, N'Battery 12V',          N'HON-BAT-010', 5,  12000,  '2024-06-22', N'Pending');
SET IDENTITY_INSERT dbo.PartsOrders OFF;

-- 7.10 ServiceAppointments
SET IDENTITY_INSERT dbo.ServiceAppointments ON;
INSERT INTO dbo.ServiceAppointments (appt_id, customer_id, dealership_id, vin, appointment_date, service_type, status, technician_name)
VALUES
    (1, 1, 1, N'JHMF C1F30MX000002', '2024-06-10', N'Oil Change',    N'Completed',  N'Ahmad Mechanic'),
    (2, 2, 2, N'JHMF C1F30MX000005', '2024-06-15', N'Full Service',  N'Scheduled',  N'Rashid Ali'),
    (3, 4, 2, N'JHMF C1F30MX000008', '2024-06-20', N'Inspection',    N'Scheduled',  N'Farhan Technician'),
    (4, 1, 1, N'JHMF C1F30MX000002', '2024-07-01', N'Repair',        N'Scheduled',  N'Ahmad Mechanic'),
    (5, 5, 1, N'JHMF C1F30MX000003', '2024-07-05', N'Oil Change',    N'Scheduled',  N'Usman Tech');
SET IDENTITY_INSERT dbo.ServiceAppointments OFF;

-- ============================================================================
-- VERIFICATION QUERIES (run these to confirm setup)
-- ============================================================================
-- Tables:       SELECT COUNT(*) AS Tables FROM sys.tables WHERE is_ms_shipped = 0;
-- Views:        SELECT COUNT(*) AS Views FROM sys.views WHERE is_ms_shipped = 0;
-- Indexes:      SELECT COUNT(*) AS Indexes FROM sys.indexes WHERE object_id IN (SELECT object_id FROM sys.tables WHERE is_ms_shipped = 0) AND name IS NOT NULL;
-- Procedures:   SELECT COUNT(*) AS Procedures FROM sys.procedures;
-- Triggers:     SELECT COUNT(*) AS Triggers FROM sys.triggers;
-- Sample data:  SELECT 'Plants' AS T, COUNT(*) AS R FROM Plants UNION ALL SELECT 'VehicleModels', COUNT(*) FROM VehicleModels UNION ALL SELECT 'ProductionBatches', COUNT(*) FROM ProductionBatches UNION ALL SELECT 'Dealerships', COUNT(*) FROM Dealerships UNION ALL SELECT 'Inventory', COUNT(*) FROM Inventory UNION ALL SELECT 'Customers', COUNT(*) FROM Customers UNION ALL SELECT 'SalesContracts', COUNT(*) FROM SalesContracts UNION ALL SELECT 'FinancingPlans', COUNT(*) FROM FinancingPlans UNION ALL SELECT 'PartsOrders', COUNT(*) FROM PartsOrders UNION ALL SELECT 'ServiceAppointments', COUNT(*) FROM ServiceAppointments ORDER BY T;
GO
