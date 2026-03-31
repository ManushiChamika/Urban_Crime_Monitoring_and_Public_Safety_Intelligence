/*
Task 4 - Data warehouse design and development
Run this script once on a new SQL Server instance or empty assignment databases.
*/

IF DB_ID(N'DWBI_Staging') IS NULL
    CREATE DATABASE DWBI_Staging;
GO

IF DB_ID(N'DWBI_Warehouse') IS NULL
    CREATE DATABASE DWBI_Warehouse;
GO

USE DWBI_Warehouse;
GO

CREATE TABLE dbo.DimDate (
    DateKey INT NOT NULL PRIMARY KEY,                -- YYYYMMDD
    FullDate DATE NOT NULL UNIQUE,
    DayNumberOfWeek TINYINT NOT NULL,
    DayName NVARCHAR(20) NOT NULL,
    DayNumberOfMonth TINYINT NOT NULL,
    MonthNumber TINYINT NOT NULL,
    MonthName NVARCHAR(20) NOT NULL,
    QuarterNumber TINYINT NOT NULL,
    YearNumber SMALLINT NOT NULL,
    WeekendFlag CHAR(1) NOT NULL
);
GO

CREATE TABLE dbo.DimOffense (
    OffenseKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    IUCR VARCHAR(10) NOT NULL,
    PrimaryType NVARCHAR(100) NOT NULL,
    OffenseDescription NVARCHAR(255) NOT NULL,
    FBICode VARCHAR(10) NULL
);
GO

CREATE UNIQUE INDEX IX_DimOffense_IUCR
    ON dbo.DimOffense (IUCR);
GO

CREATE TABLE dbo.DimLocation (
    LocationKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Block NVARCHAR(100) NULL,
    LocationDescription NVARCHAR(100) NULL,
    Latitude DECIMAL(10,7) NULL,
    Longitude DECIMAL(10,7) NULL,
    XCoordinate INT NULL,
    YCoordinate INT NULL,
    LocationText NVARCHAR(100) NULL
);
GO

CREATE INDEX IX_DimLocation_Natural
    ON dbo.DimLocation (Block, LocationDescription, Latitude, Longitude);
GO

CREATE TABLE dbo.DimPoliceArea (
    PoliceAreaKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    DistrictCode VARCHAR(10) NOT NULL,
    BeatCode VARCHAR(10) NOT NULL,
    WardCode VARCHAR(10) NULL,
    CommunityAreaCode VARCHAR(10) NULL,
    EffectiveFrom DATETIME2(0) NOT NULL,
    EffectiveTo DATETIME2(0) NOT NULL,
    IsCurrent BIT NOT NULL
);
GO

CREATE INDEX IX_DimPoliceArea_BusinessKey
    ON dbo.DimPoliceArea (DistrictCode, BeatCode, IsCurrent);
GO

CREATE TABLE dbo.FactCrimeIncident (
    FactIncidentKey BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    IncidentID BIGINT NOT NULL,
    CaseNumber VARCHAR(30) NOT NULL,                -- degenerate dimension
    DateKey INT NOT NULL,
    OffenseKey INT NOT NULL,
    LocationKey INT NOT NULL,
    PoliceAreaKey INT NOT NULL,
    IncidentCount INT NOT NULL CONSTRAINT DF_FactCrimeIncident_IncidentCount DEFAULT (1),
    ArrestCount INT NOT NULL,
    DomesticCount INT NOT NULL,
    SourceUpdatedOn DATETIME2(0) NULL,
    CONSTRAINT UQ_FactCrimeIncident_IncidentID UNIQUE (IncidentID),
    CONSTRAINT FK_FactCrimeIncident_DimDate
        FOREIGN KEY (DateKey) REFERENCES dbo.DimDate(DateKey),
    CONSTRAINT FK_FactCrimeIncident_DimOffense
        FOREIGN KEY (OffenseKey) REFERENCES dbo.DimOffense(OffenseKey),
    CONSTRAINT FK_FactCrimeIncident_DimLocation
        FOREIGN KEY (LocationKey) REFERENCES dbo.DimLocation(LocationKey),
    CONSTRAINT FK_FactCrimeIncident_DimPoliceArea
        FOREIGN KEY (PoliceAreaKey) REFERENCES dbo.DimPoliceArea(PoliceAreaKey)
);
GO

CREATE INDEX IX_FactCrimeIncident_DateKey
    ON dbo.FactCrimeIncident (DateKey);
GO

CREATE INDEX IX_FactCrimeIncident_OffenseKey
    ON dbo.FactCrimeIncident (OffenseKey);
GO

CREATE INDEX IX_FactCrimeIncident_LocationKey
    ON dbo.FactCrimeIncident (LocationKey);
GO

CREATE INDEX IX_FactCrimeIncident_PoliceAreaKey
    ON dbo.FactCrimeIncident (PoliceAreaKey);
GO

/* Unknown rows for lookup failures */
INSERT INTO dbo.DimDate
    (DateKey, FullDate, DayNumberOfWeek, DayName, DayNumberOfMonth, MonthNumber, MonthName, QuarterNumber, YearNumber, WeekendFlag)
VALUES
    (0, '1900-01-01', 1, N'Unknown', 0, 0, N'Unknown', 0, 1900, 'N');
GO

SET IDENTITY_INSERT dbo.DimOffense ON;
INSERT INTO dbo.DimOffense
    (OffenseKey, IUCR, PrimaryType, OffenseDescription, FBICode)
VALUES
    (0, 'UNK', N'Unknown', N'Unknown', 'UNK');
SET IDENTITY_INSERT dbo.DimOffense OFF;
GO

SET IDENTITY_INSERT dbo.DimLocation ON;
INSERT INTO dbo.DimLocation
    (LocationKey, Block, LocationDescription, Latitude, Longitude, XCoordinate, YCoordinate, LocationText)
VALUES
    (0, N'Unknown', N'Unknown', NULL, NULL, NULL, NULL, N'Unknown');
SET IDENTITY_INSERT dbo.DimLocation OFF;
GO

SET IDENTITY_INSERT dbo.DimPoliceArea ON;
INSERT INTO dbo.DimPoliceArea
    (PoliceAreaKey, DistrictCode, BeatCode, WardCode, CommunityAreaCode, EffectiveFrom, EffectiveTo, IsCurrent)
VALUES
    (0, 'UNK', 'UNK', NULL, NULL, '1900-01-01', '9999-12-31', 1);
SET IDENTITY_INSERT dbo.DimPoliceArea OFF;
GO
