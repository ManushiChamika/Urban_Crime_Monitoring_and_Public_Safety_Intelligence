/*
Task 5 - ETL support SQL for SSIS
SSIS should extract the CSV/TXT/XLSX files into these staging tables first.
Then run the dimension and fact load queries in this order:
1. Truncate staging
2. Load staging from SSIS data flows
3. Load DimDate
4. Load DimOffense
5. Load DimLocation
6. Load DimPoliceArea (Type 2)
7. Load FactCrimeIncident
8. Run validation queries
*/

USE DWBI_Staging;
GO

CREATE TABLE dbo.stg_CrimeIncident (
    IncidentID BIGINT NULL,
    CaseNumber VARCHAR(30) NULL,
    IncidentDate DATETIME2(0) NULL,
    Block NVARCHAR(100) NULL,
    LocationDescription NVARCHAR(100) NULL,
    Arrest BIT NULL,
    Domestic BIT NULL,
    Beat VARCHAR(10) NULL,
    District VARCHAR(10) NULL,
    Ward VARCHAR(10) NULL,
    CommunityArea VARCHAR(10) NULL,
    IncidentYear INT NULL,
    UpdatedOn DATETIME2(0) NULL,
    Latitude DECIMAL(10,7) NULL,
    Longitude DECIMAL(10,7) NULL,
    IUCR VARCHAR(10) NULL,
    StageLoadDts DATETIME2(0) NOT NULL CONSTRAINT DF_stg_CrimeIncident_StageLoadDts DEFAULT (SYSDATETIME())
);
GO

CREATE TABLE dbo.stg_Offense (
    IUCR VARCHAR(10) NULL,
    PrimaryType NVARCHAR(100) NULL,
    OffenseDescription NVARCHAR(255) NULL,
    FBICode VARCHAR(10) NULL,
    StageLoadDts DATETIME2(0) NOT NULL CONSTRAINT DF_stg_Offense_StageLoadDts DEFAULT (SYSDATETIME())
);
GO

CREATE TABLE dbo.stg_Coordinate (
    Latitude DECIMAL(10,7) NULL,
    Longitude DECIMAL(10,7) NULL,
    XCoordinate INT NULL,
    YCoordinate INT NULL,
    LocationText NVARCHAR(100) NULL,
    StageLoadDts DATETIME2(0) NOT NULL CONSTRAINT DF_stg_Coordinate_StageLoadDts DEFAULT (SYSDATETIME())
);
GO

TRUNCATE TABLE dbo.stg_CrimeIncident;
TRUNCATE TABLE dbo.stg_Offense;
TRUNCATE TABLE dbo.stg_Coordinate;
GO

/* After SSIS loads staging, run the remaining steps */
USE DWBI_Warehouse;
GO

DECLARE @StartDate DATE = (
    SELECT MIN(CAST(IncidentDate AS DATE))
    FROM DWBI_Staging.dbo.stg_CrimeIncident
);

DECLARE @EndDate DATE = (
    SELECT MAX(CAST(IncidentDate AS DATE))
    FROM DWBI_Staging.dbo.stg_CrimeIncident
);

;WITH DateSeries AS (
    SELECT @StartDate AS FullDate
    UNION ALL
    SELECT DATEADD(DAY, 1, FullDate)
    FROM DateSeries
    WHERE FullDate < @EndDate
)
INSERT INTO dbo.DimDate
    (DateKey, FullDate, DayNumberOfWeek, DayName, DayNumberOfMonth, MonthNumber, MonthName, QuarterNumber, YearNumber, WeekendFlag)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), FullDate, 112)) AS DateKey,
    FullDate,
    DATEPART(WEEKDAY, FullDate) AS DayNumberOfWeek,
    DATENAME(WEEKDAY, FullDate) AS DayName,
    DATEPART(DAY, FullDate) AS DayNumberOfMonth,
    DATEPART(MONTH, FullDate) AS MonthNumber,
    DATENAME(MONTH, FullDate) AS MonthName,
    DATEPART(QUARTER, FullDate) AS QuarterNumber,
    DATEPART(YEAR, FullDate) AS YearNumber,
    CASE WHEN DATEPART(WEEKDAY, FullDate) IN (1, 7) THEN 'Y' ELSE 'N' END AS WeekendFlag
FROM DateSeries d
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.DimDate x
    WHERE x.FullDate = d.FullDate
)
OPTION (MAXRECURSION 0);
GO

INSERT INTO dbo.DimOffense
    (IUCR, PrimaryType, OffenseDescription, FBICode)
SELECT
    s.IUCR,
    s.PrimaryType,
    s.OffenseDescription,
    s.FBICode
FROM DWBI_Staging.dbo.stg_Offense s
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.DimOffense d
    WHERE d.IUCR = s.IUCR
);
GO

UPDATE d
SET
    d.PrimaryType = s.PrimaryType,
    d.OffenseDescription = s.OffenseDescription,
    d.FBICode = s.FBICode
FROM dbo.DimOffense d
JOIN DWBI_Staging.dbo.stg_Offense s
    ON d.IUCR = s.IUCR
WHERE
    ISNULL(d.PrimaryType, N'') <> ISNULL(s.PrimaryType, N'')
    OR ISNULL(d.OffenseDescription, N'') <> ISNULL(s.OffenseDescription, N'')
    OR ISNULL(d.FBICode, '') <> ISNULL(s.FBICode, '');
GO

;WITH LocationSource AS (
    SELECT DISTINCT
        s.Block,
        s.LocationDescription,
        s.Latitude,
        s.Longitude,
        c.XCoordinate,
        c.YCoordinate,
        c.LocationText
    FROM DWBI_Staging.dbo.stg_CrimeIncident s
    LEFT JOIN DWBI_Staging.dbo.stg_Coordinate c
        ON c.Latitude = s.Latitude
       AND c.Longitude = s.Longitude
)
INSERT INTO dbo.DimLocation
    (Block, LocationDescription, Latitude, Longitude, XCoordinate, YCoordinate, LocationText)
SELECT
    src.Block,
    src.LocationDescription,
    src.Latitude,
    src.Longitude,
    src.XCoordinate,
    src.YCoordinate,
    src.LocationText
FROM LocationSource src
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.DimLocation d
    WHERE ISNULL(d.Block, N'') = ISNULL(src.Block, N'')
      AND ISNULL(d.LocationDescription, N'') = ISNULL(src.LocationDescription, N'')
      AND ISNULL(d.Latitude, -999.0) = ISNULL(src.Latitude, -999.0)
      AND ISNULL(d.Longitude, -999.0) = ISNULL(src.Longitude, -999.0)
      AND ISNULL(d.XCoordinate, -1) = ISNULL(src.XCoordinate, -1)
      AND ISNULL(d.YCoordinate, -1) = ISNULL(src.YCoordinate, -1)
      AND ISNULL(d.LocationText, N'') = ISNULL(src.LocationText, N'')
);
GO

;WITH PoliceAreaSource AS (
    SELECT DISTINCT
        District,
        Beat,
        Ward,
        CommunityArea
    FROM DWBI_Staging.dbo.stg_CrimeIncident
    WHERE District IS NOT NULL
      AND Beat IS NOT NULL
)
UPDATE d
SET
    d.EffectiveTo = DATEADD(SECOND, -1, SYSDATETIME()),
    d.IsCurrent = 0
FROM dbo.DimPoliceArea d
JOIN PoliceAreaSource s
    ON d.DistrictCode = s.District
   AND d.BeatCode = s.Beat
   AND d.IsCurrent = 1
WHERE
    ISNULL(d.WardCode, '') <> ISNULL(s.Ward, '')
    OR ISNULL(d.CommunityAreaCode, '') <> ISNULL(s.CommunityArea, '');
GO

;WITH PoliceAreaSource AS (
    SELECT DISTINCT
        District,
        Beat,
        Ward,
        CommunityArea
    FROM DWBI_Staging.dbo.stg_CrimeIncident
    WHERE District IS NOT NULL
      AND Beat IS NOT NULL
)
INSERT INTO dbo.DimPoliceArea
    (DistrictCode, BeatCode, WardCode, CommunityAreaCode, EffectiveFrom, EffectiveTo, IsCurrent)
SELECT
    s.District,
    s.Beat,
    s.Ward,
    s.CommunityArea,
    SYSDATETIME(),
    '9999-12-31',
    1
FROM PoliceAreaSource s
LEFT JOIN dbo.DimPoliceArea d
    ON d.DistrictCode = s.District
   AND d.BeatCode = s.Beat
   AND d.IsCurrent = 1
WHERE
    d.PoliceAreaKey IS NULL
    OR ISNULL(d.WardCode, '') <> ISNULL(s.Ward, '')
    OR ISNULL(d.CommunityAreaCode, '') <> ISNULL(s.CommunityArea, '');
GO

INSERT INTO dbo.FactCrimeIncident
    (IncidentID, CaseNumber, DateKey, OffenseKey, LocationKey, PoliceAreaKey, IncidentCount, ArrestCount, DomesticCount, SourceUpdatedOn)
SELECT
    s.IncidentID,
    s.CaseNumber,
    ISNULL(d.DateKey, 0) AS DateKey,
    ISNULL(o.OffenseKey, 0) AS OffenseKey,
    ISNULL(l.LocationKey, 0) AS LocationKey,
    ISNULL(p.PoliceAreaKey, 0) AS PoliceAreaKey,
    1 AS IncidentCount,
    CASE WHEN s.Arrest = 1 THEN 1 ELSE 0 END AS ArrestCount,
    CASE WHEN s.Domestic = 1 THEN 1 ELSE 0 END AS DomesticCount,
    s.UpdatedOn
FROM DWBI_Staging.dbo.stg_CrimeIncident s
LEFT JOIN dbo.DimDate d
    ON d.FullDate = CAST(s.IncidentDate AS DATE)
LEFT JOIN dbo.DimOffense o
    ON o.IUCR = s.IUCR
LEFT JOIN dbo.DimLocation l
    ON ISNULL(l.Block, N'') = ISNULL(s.Block, N'')
   AND ISNULL(l.LocationDescription, N'') = ISNULL(s.LocationDescription, N'')
   AND ISNULL(l.Latitude, -999.0) = ISNULL(s.Latitude, -999.0)
   AND ISNULL(l.Longitude, -999.0) = ISNULL(s.Longitude, -999.0)
LEFT JOIN dbo.DimPoliceArea p
    ON p.DistrictCode = s.District
   AND p.BeatCode = s.Beat
   AND ISNULL(p.WardCode, '') = ISNULL(s.Ward, '')
   AND ISNULL(p.CommunityAreaCode, '') = ISNULL(s.CommunityArea, '')
   AND p.IsCurrent = 1
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.FactCrimeIncident f
    WHERE f.IncidentID = s.IncidentID
);
GO

/* Validation queries you can include in the report */
SELECT 'stg_CrimeIncident' AS TableName, COUNT(*) AS RowCount FROM DWBI_Staging.dbo.stg_CrimeIncident
UNION ALL
SELECT 'stg_Offense', COUNT(*) FROM DWBI_Staging.dbo.stg_Offense
UNION ALL
SELECT 'stg_Coordinate', COUNT(*) FROM DWBI_Staging.dbo.stg_Coordinate
UNION ALL
SELECT 'DimDate', COUNT(*) FROM dbo.DimDate
UNION ALL
SELECT 'DimOffense', COUNT(*) FROM dbo.DimOffense
UNION ALL
SELECT 'DimLocation', COUNT(*) FROM dbo.DimLocation
UNION ALL
SELECT 'DimPoliceArea', COUNT(*) FROM dbo.DimPoliceArea
UNION ALL
SELECT 'FactCrimeIncident', COUNT(*) FROM dbo.FactCrimeIncident;
GO

SELECT IncidentID, COUNT(*) AS DuplicateCount
FROM DWBI_Staging.dbo.stg_CrimeIncident
GROUP BY IncidentID
HAVING COUNT(*) > 1;
GO

SELECT DistrictCode, BeatCode, COUNT(*) AS CurrentRows
FROM dbo.DimPoliceArea
WHERE IsCurrent = 1
GROUP BY DistrictCode, BeatCode
HAVING COUNT(*) > 1;
GO

SELECT
    SUM(CASE WHEN OffenseKey = 0 THEN 1 ELSE 0 END) AS UnknownOffenseFacts,
    SUM(CASE WHEN LocationKey = 0 THEN 1 ELSE 0 END) AS UnknownLocationFacts,
    SUM(CASE WHEN PoliceAreaKey = 0 THEN 1 ELSE 0 END) AS UnknownPoliceAreaFacts
FROM dbo.FactCrimeIncident;
GO
