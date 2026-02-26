# Data Warehousing & Business Intelligence

## Dataset Selection (OLTP)

This repository documents a complete, assignment-ready OLTP dataset selection and preparation for DW/BI work.

## Selected Scenario

### Urban Crime Monitoring and Public Safety Intelligence (Chicago)

Business use:
- Crime trend analysis by date and area
- Offense-type and FBI-code analysis
- Location and hotspot analysis
- Arrest and domestic incident monitoring

## Dataset Chosen

- Base source (unchanged): `data/crimes_original_full.csv`
- Domain: Transactional crime incidents
- Incident time range (`Date`): **2023-01-01 00:00:00** to **2023-12-31 23:59:00** (full 1 year)

## Final 3 Linked Raw Datasets

| Dataset | Rows | Columns | PK | FK |
|---|---:|---:|---|---|
| `data/crimes_original_reduced.csv` | 263,271 | 16 | `ID` | `IUCR` -> `offense_source.IUCR`; (`Latitude`,`Longitude`) -> (`location_source.Latitude`,`location_source.Longitude`) |
| `data/offense_source.csv` | 322 | 4 | `IUCR` | Referenced by `crimes_original_reduced.IUCR` |
| `data/location_source.csv` | 128,677 | 5 | (`Latitude`,`Longitude`) | Referenced by `crimes_original_reduced` coordinate pair |

## Columns (All)

### `data/crimes_original_reduced.csv` (16)
- `ID`, `Case Number`, `Date`, `IUCR`, `Latitude`, `Longitude`, `Block`, `Location Description`, `Arrest`, `Domestic`, `Beat`, `District`, `Ward`, `Community Area`, `Year`, `Updated On`

### `data/offense_source.csv` (4)
- `IUCR`, `Primary Type`, `Description`, `FBI Code`

### `data/location_source.csv` (5)
- `Location`, `Latitude`, `Longitude`, `X Coordinate`, `Y Coordinate`

## Assignment Requirement Checklist

| Requirement | Status | Evidence in this repo |
|---|---|---|
| OLTP dataset only (not OLAP) | Satisfied | `data/crimes_original_full.csv` is row-level transactional source data with no pre-built fact/dimension schema |
| Uniqueness (not lab dataset / not AdventureWorks) | Satisfied | Scenario and source are crime-incident data, not AdventureWorks |
| At least ~1 year of data | Satisfied | Incident `Date` covers full year 2023 |
| Rich attributes and relationships | Satisfied | 3 linked datasets with event, offense reference, and location reference entities |
| Suitable for ETL, DW design, SSAS, reporting | Satisfied | PK/FK model and source separation support ETL pipelines and downstream DW/BI modeling |

## Relationship Model (ER-Style)

- `offense_source (IUCR)` 1-to-many `crimes_original_reduced (IUCR)`
- `location_source (Latitude, Longitude)` 1-to-many `crimes_original_reduced (Latitude, Longitude)` for non-null coordinates

## Step-by-Step Process

1. Identify scenario and business questions.
2. Validate source as OLTP and confirm date coverage >= 1 year.
3. Identify entities and keys from source columns.
4. Build reduced main transaction dataset (`crimes_original_reduced.csv`).
5. Build offense reference dataset (`offense_source.csv`).
6. Build location reference dataset (`location_source.csv`).
7. Validate PK/FK integrity and uniqueness.
8. Document data quality issues and handling rules.
9. Prepare final submission artifacts (dataset summary, ER diagram, justification, extension note).

## Tools in Order (Mapped to Steps)

| Steps | Task | Recommended tools |
|---|---|---|
| 1-2 | Source review, counts, date-range checks | `VS Code`/`Excel`, `Python (pandas)` |
| 3 | Key discovery and relationship checks | `Python (pandas)` |
| 4-6 | Dataset splitting, cleanup, CSV export | `Python (pandas)` or `SQL Server (SSMS)` |
| 7 | PK/FK validation, null/duplicate checks | `Python (pandas)` or `SSMS SQL` |
| 8-9 | Documentation, ER diagram, submission pack | `README.md`, `draw.io`/`dbdiagram.io`, `Word/PDF` |

## Tool Mapping for DW/BI Requirement

To demonstrate the requirement "ETL processes, data warehouse design, SSAS cubes, and reporting", use:

| Requirement Area | Recommended Tools |
|---|---|
| ETL processes | `SSIS` (primary), or `Python (pandas)` / `SQL stored procedures` |
| Data warehouse design | `SQL Server` + `SSMS` (staging, PK/FK, DW schema), `draw.io` / `dbdiagram.io` (ER design) |
| SSAS cubes | `SQL Server Analysis Services (SSAS)` |
| Reporting | `Power BI` (recommended) or `SSRS` / `Excel Pivot` |

Suggested end-to-end stack:
- `Python/pandas` -> `SQL Server/SSMS` -> `SSIS` -> `SSAS` -> `Power BI`

Minimum toolchain:
- `Python 3.x`
- `pandas`
- `VS Code`
- `draw.io` (or equivalent ER tool)

## Data Quality Note

- Rows with null latitude/longitude: `2,028` (`~0.77%` of crime rows)
- Impact: small; non-location analyses are unaffected
- ETL handling: map these rows to `Unknown Location` when full location joins are required

## Files

- Root-level assignment overview: `README.md`
- Detailed data dictionary and linkage notes: `data/README.md`
- Original unchanged source kept for traceability: `data/crimes_original_full.csv`
