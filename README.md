
## Scenario

### Urban Crime Monitoring and Public Safety Intelligence (Chicago)

The project scenario is to analyze crime incidents to support public safety decisions such as:
- crime trend analysis by month and area
- offense pattern analysis (type, description, FBI code)
- hotspot and location-based analysis
- arrest/domestic incident monitoring

Contains high transaction volume, rich attributes, and clear business questions.

## Selected OLTP Source

- Source file: `data/crimes_original_full.csv`
- Domain: Crime incident transactions
- Time range covered: **January 1, 2023 to December 31, 2023**
- OLTP suitability: Raw row-level transaction records (not pre-modeled as OLAP facts/dimensions)

## Active 3 Raw Linked Datasets

These are the 3 working datasets:

| Dataset | Rows | Columns | Primary Key | Foreign Key Links |
|---|---:|---:|---|---|
| `data/crimes_original_reduced.csv` | 263,271 | 16 | `ID` | `IUCR` -> `offense_source.IUCR`; (`Latitude`,`Longitude`) -> (`location_source.Latitude`,`location_source.Longitude`) |
| `data/offense_source.csv` | 322 | 4 | `IUCR` | Referenced by `crimes_original_reduced.IUCR` |
| `data/location_source.csv` | 128,677 | 5 | (`Latitude`,`Longitude`) | Referenced by `crimes_original_reduced` coordinate pair |

## What Each Dataset Tells

### 1) `crimes_original_reduced.csv`

One row per crime event with core event details and link keys.

Columns:
- `ID`, `Case Number`, `Date`, `IUCR`, `Latitude`, `Longitude`, `Block`, `Location Description`, `Arrest`, `Domestic`, `Beat`, `District`, `Ward`, `Community Area`, `Year`, `Updated On`

### 2) `offense_source.csv`

Offense code reference dictionary (meaning of each `IUCR` code).

Columns:
- `IUCR`, `Primary Type`, `Description`, `FBI Code`

### 3) `location_source.csv`

Location reference points used for coordinate-based linking.

Columns:
- `Location`, `Latitude`, `Longitude`, `X Coordinate`, `Y Coordinate`

## Relationship Structure (ER-style)

- `offense_source (IUCR)` 1-to-many `crimes_original_reduced (IUCR)`
- `location_source (Latitude, Longitude)` 1-to-many `crimes_original_reduced (Latitude, Longitude)` for non-null coordinates

## Requirements satisfied

- OLTP only: Uses raw transaction-level crime records.
- Unique scenario: Not AdventureWorks and not lab dataset.
- Time coverage: Full year of 2023 (meets >= 1 year requirement).
- Rich attributes and relationships: Multiple entities and key links.
- DW/BI readiness: Supports ETL, warehouse modeling, cubes, and reporting later.

## Step-by-Step Process

1. Identify the scenario.
   - Choose a business problem: city crime monitoring and public safety analytics.
2. Validate the raw OLTP source.
   - Confirm row-level transactional structure and one-year minimum time coverage.
3. Define entities and relationships from source attributes.
   - Crime events (`ID`), offense codes (`IUCR`), and locations (`Latitude`,`Longitude`).
4. Create dataset 1: `crimes_original_reduced.csv`.
   - Keep crime event columns and foreign key columns.
   - Remove columns moved to reference sources (`Primary Type`, `Description`, `FBI Code`, `Location`, `X Coordinate`, `Y Coordinate`).
5. Create dataset 2: `offense_source.csv`.
   - Build unique `IUCR` records with offense descriptors.
6. Create dataset 3: `location_source.csv`.
   - Build unique coordinate-pair records with location metadata.
7. Validate keys and relationships.
   - `ID` unique in reduced crimes table.
   - `IUCR` unique in offense table.
   - (`Latitude`,`Longitude`) unique in location table.
   - No missing FK matches for `IUCR` and non-null coordinate pairs.
8. Document data quality notes.
   - 2,028 crime rows have null latitude/longitude (~0.77%); these can be mapped to `Unknown Location` in ETL when full location joins are required.
9. Prepare assignment deliverables.
   - Dataset names and source
   - Record counts, column counts, and time range
   - PK/FK mapping and ER-style relationship diagram
   - Justification and optional synthetic extension plan

## Tools in Order for Steps

| Step | What to do | Recommended tools |
|---|---|---|
| 1-2 | Pick scenario and verify OLTP/time range | `VS Code`/`Excel` for quick view, `Python (pandas)` for counts and date checks |
| 3 | Identify entities and key relationships | `Python (pandas)` for uniqueness checks, `draw.io`/`dbdiagram.io` for ER sketch |
| 4-6 | Create the 3 linked datasets | `Python (pandas)` for split/clean/export CSV (or `SSMS SQL` if preferred) |
| 7 | Validate PK/FK and data quality | `Python (pandas)` or `SSMS SQL` for key/null/FK checks |
| 8 | Document caveats and handling | `README.md` and `docs/process.md` |
| 9 | Final submission pack | `draw.io` for ER diagram export, `Word/PDF` for report formatting |

Minimum toolchain used in this repo:
- `Python 3.x`
- `pandas`
- `VS Code`
- `draw.io` (or equivalent ER tool)

## Notes

- Original unchanged source is retained at `data/crimes_original_full.csv`.
- Detailed dataset-level documentation is available in `data/README.md`.
