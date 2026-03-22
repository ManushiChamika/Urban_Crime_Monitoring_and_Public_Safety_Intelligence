# Data Source Preparation

## Files in This Folder

| File | Type | Role |
|---|---|---|
| `Crimes_-_2001_to_Present_20260321.csv` | CSV | Original raw dataset kept unchanged |
| `crimes_original_reduced.csv` | CSV | Main incident source after removing offense and coordinate detail columns |
| `offense_source.txt` | Text (tab-delimited) | Offense lookup source |
| `coordinate_source.csv` | CSV | Coordinate lookup source keyed by `Latitude` and `Longitude` |
| `source_validation.txt` | Text | PK/FK and row-count validation report |
| `dataset_link.txt` | Text | Original public dataset link |

## Source Types Achieved

The prepared sources now use:

- `3` raw data sources
- `2` source types: `CSV` and `Text`

## Natural-Key-Only Preparation

No surrogate keys were added in the prepared-source stage.

- incident primary key uses original column `ID`
- offense primary key uses original column `IUCR`
- coordinate primary key uses original composite `(Latitude, Longitude)`
- the incident source keeps `IUCR`, `Latitude`, and `Longitude` as natural foreign keys

This keeps the preparation layer close to the original OLTP data. Surrogate keys can be introduced later in the warehouse design.

## 1) crimes_original_reduced.csv

Meaning:

- one row per crime incident
- this is the main transactional source
- it keeps the event-level attributes and the natural foreign keys

Primary key:

- `ID`

Foreign keys:

- `IUCR -> offense_source.txt.IUCR`
- `(Latitude, Longitude) -> coordinate_source.csv.(Latitude, Longitude)` for non-null pairs

Rows:

- `759,161`

Columns:

- `ID`
- `Case Number`
- `Date`
- `Block`
- `Location Description`
- `Arrest`
- `Domestic`
- `Beat`
- `District`
- `Ward`
- `Community Area`
- `Year`
- `Updated On`
- `Latitude`
- `Longitude`
- `IUCR`

Columns removed from the raw file because they were moved to other sources:

- `Primary Type`
- `Description`
- `FBI Code`
- `X Coordinate`
- `Y Coordinate`
- `Location`

## 2) offense_source.txt

Meaning:

- offense code dictionary derived from the raw dataset
- one record per distinct `IUCR`
- stored as a tab-delimited text file to provide a second source type

Primary key:

- `IUCR`

Rows:

- `359`

Columns:

- `IUCR`
- `Primary Type`
- `Description`
- `FBI Code`

Key quality:

- `IUCR` is unique
- each `IUCR` maps to exactly one offense definition in the source snapshot

## 3) coordinate_source.csv

Meaning:

- coordinate lookup derived from the raw dataset
- one record per distinct non-null `Latitude` and `Longitude` pair
- it isolates reusable spatial attributes without adding a surrogate key

Primary key:

- composite key: `Latitude`, `Longitude`

Rows:

- `248,591`

Columns:

- `Latitude`
- `Longitude`
- `X Coordinate`
- `Y Coordinate`
- `Location`

Key quality:

- each non-null `Latitude` and `Longitude` pair maps to exactly one `X Coordinate`, `Y Coordinate`, and `Location`

## Relationship Summary

- `offense_source.txt (IUCR)` has a one-to-many relationship with `crimes_original_reduced.csv (IUCR)`
- `coordinate_source.csv (Latitude, Longitude)` has a one-to-many relationship with `crimes_original_reduced.csv (Latitude, Longitude)` for non-null coordinate pairs

## Validation Results

The preparation was checked after file generation.

- Raw rows processed: `759,161`
- Incident rows written: `759,161`
- Offense rows written: `359`
- Coordinate rows written: `248,591`
- Duplicate incident IDs found: `0`
- Inconsistent IUCR definitions found: `0`
- Inconsistent coordinate definitions found: `0`
- Missing `IUCR` foreign keys: `0`
- Missing non-null coordinate foreign keys: `0`
- Incident rows with blank `Latitude` or `Longitude`: `4,261`
- Surrogate keys added during source preparation: `0`

See:

- `source_validation.txt`

## Why These Sources Are Meaningful

- `crimes_original_reduced.csv` stays at the original transaction grain
- `offense_source.txt` isolates a reusable offense classification entity
- `coordinate_source.csv` isolates reusable spatial coordinate attributes
- the split creates three raw data sources without inventing new business attributes or surrogate identifiers

This makes the prepared sources appropriate for ETL, later dimensional modeling, SSAS, and reporting.
