# Data Sources

This folder uses 3 linked raw datasets for the assignment.

## 1) crimes_original_reduced.csv

What this dataset tells:
- One row per crime event, with core event details and link keys to offense and location reference datasets.

Primary key:
- `ID`

Foreign keys:
- `IUCR` -> `offense_source.IUCR`
- (`Latitude`, `Longitude`) -> (`location_source.Latitude`, `location_source.Longitude`) when coordinates are available

Rows:
- `263,271`

Number of columns:
- `16`

Columns (all):
- `ID`, `Case Number`, `Date`, `IUCR`, `Latitude`, `Longitude`, `Block`, `Location Description`, `Arrest`, `Domestic`, `Beat`, `District`, `Ward`, `Community Area`, `Year`, `Updated On`

## 2) offense_source.csv

What this dataset tells:
- Offense code dictionary. It explains each crime code and its offense classification.

Primary key:
- `IUCR`

Rows:
- `322`

Number of columns:
- `4`

Columns (all):
- `IUCR`, `Primary Type`, `Description`, `FBI Code`

## 3) location_source.csv

What this dataset tells:
- Standardized location reference points for crime events (coordinates and matching location string).

Composite primary key:
- (`Latitude`, `Longitude`)

Rows:
- `128,677`

Number of columns:
- `5`

Columns (all):
- `Location`, `Latitude`, `Longitude`, `X Coordinate`, `Y Coordinate`

## Are These 3 Datasets Meaningful and Usable?

Usable as linked raw datasets because they separate:
- event records (`crimes_original_reduced.csv`)
- offense reference data (`offense_source.csv`)
- location reference data (`location_source.csv`)

Link quality checks:
- Missing `IUCR` matches in offense source: `0`
- Missing non-null (`Latitude`, `Longitude`) matches in location source: `0`
- Crime rows with null latitude/longitude (cannot link to location source): `2,028`
    Note on impact:
    - This is a small share of total rows (`~0.77%`), so it is not a major issue.
    - For ETL, these rows can be mapped to an `Unknown Location` record when a complete location join is required.

## Original Raw File Kept

- `crimes_original_full.csv` is kept unchanged as the original source extract.
