/*
Task 6 - Accumulating fact support
This script extends FactCrimeIncident so the row is inserted first and updated later
when a completion timestamp arrives from a separate source.
*/

USE DWBI_Warehouse;
GO

ALTER TABLE dbo.FactCrimeIncident
ADD
    CreateTime DATETIME2(0) NULL,
    CompletionTime DATETIME2(0) NULL,
    ProcessingDurationHours DECIMAL(10,2) NULL;
GO

ALTER TABLE dbo.FactCrimeIncident
ADD CONSTRAINT DF_FactCrimeIncident_CreateTime DEFAULT (SYSDATETIME()) FOR CreateTime;
GO

UPDATE dbo.FactCrimeIncident
SET CreateTime = ISNULL(CreateTime, SYSDATETIME());
GO

ALTER TABLE dbo.FactCrimeIncident
ALTER COLUMN CreateTime DATETIME2(0) NOT NULL;
GO

USE DWBI_Staging;
GO

CREATE TABLE dbo.stg_IncidentCompletion (
    IncidentID BIGINT NULL,
    CompletionTime DATETIME2(0) NULL,
    StageLoadDts DATETIME2(0) NOT NULL CONSTRAINT DF_stg_IncidentCompletion_StageLoadDts DEFAULT (SYSDATETIME())
);
GO

TRUNCATE TABLE dbo.stg_IncidentCompletion;
GO

/*
SSIS package 2 loads the separate completion file into stg_IncidentCompletion.
After the staging load finishes, run the update below.
*/
USE DWBI_Warehouse;
GO

;WITH CompletionSource AS (
    SELECT
        IncidentID,
        MAX(CompletionTime) AS CompletionTime
    FROM DWBI_Staging.dbo.stg_IncidentCompletion
    WHERE CompletionTime IS NOT NULL
    GROUP BY IncidentID
)
UPDATE f
SET
    f.CompletionTime = s.CompletionTime,
    f.ProcessingDurationHours = CAST(DATEDIFF(MINUTE, f.CreateTime, s.CompletionTime) / 60.0 AS DECIMAL(10,2))
FROM dbo.FactCrimeIncident f
JOIN CompletionSource s
    ON s.IncidentID = f.IncidentID
WHERE
    s.CompletionTime >= f.CreateTime
    AND (f.CompletionTime IS NULL OR s.CompletionTime > f.CompletionTime);
GO

/* Validation queries for the second package */
SELECT
    COUNT(*) AS CompletedFacts
FROM dbo.FactCrimeIncident
WHERE CompletionTime IS NOT NULL;
GO

SELECT
    COUNT(*) AS OpenFacts
FROM dbo.FactCrimeIncident
WHERE CompletionTime IS NULL;
GO

SELECT
    COUNT(*) AS NegativeDurationRows
FROM dbo.FactCrimeIncident
WHERE ProcessingDurationHours < 0;
GO

SELECT s.IncidentID, s.CompletionTime
FROM DWBI_Staging.dbo.stg_IncidentCompletion s
LEFT JOIN dbo.FactCrimeIncident f
    ON f.IncidentID = s.IncidentID
WHERE f.IncidentID IS NULL;
GO
