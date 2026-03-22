# Data Warehousing and Business Intelligence Assignment

## Selected Scenario

### Urban Public Safety Incident Response and Community Risk Intelligence

This is a police incident dataset for a public-safety DW/BI scenario. The source is OLTP-style as each row is a single recorded incident, not a pre-built fact table or OLAP cube.

## Original Dataset in the Repo

- Raw file: `data/Crimes_-_2001_to_Present_20260321.csv`
- Source: City of Chicago Data Portal, `Crimes - 2001 to Present`
- Grain: one row per incident
- Local row count: `759,161`
- Column count: `22`
- Local `Date` range: `2023-01-01 00:00:00` to `2026-01-01 00:00:00`

Important note:
Although the original public dataset spans 2001 to the present, the local currently stored includes only records from January 1, 2023, to January 1, 2026. Since loading the full dataset of approximately 7 million records into the data warehouse is not feasible, the data is reduced for the ELT process to include only records from 2023–2026.

## Prepared Data Sources

The raw dataset has been separated into three meaningful raw sources using only original columns from the source data.

| Source | Type | Rows | Primary key | Foreign keys / relationship |
|---|---|---:|---|---|
| `data/crimes_original_reduced.csv` | CSV | `759,161` | `ID` | `IUCR -> offense_source.txt.IUCR`; `(Latitude, Longitude) -> coordinate_source.csv.(Latitude, Longitude)` for non-null pairs |
| `data/offense_source.txt` | Text (tab-delimited) | `359` | `IUCR` | Referenced by `crimes_original_reduced.csv` |
| `data/coordinate_source.csv` | CSV | `248,591` | `(Latitude, Longitude)` | Referenced by `crimes_original_reduced.csv` for non-null pairs |

This gives:

- `3` raw data sources
- `2` source types: `CSV` and `Text`

## Raw Columns Were Split were split as follows:

### Kept in `crimes_original_reduced.csv`

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

### Moved to `offense_source.txt`

- `IUCR`
- `Primary Type`
- `Description`
- `FBI Code`

### Moved to `coordinate_source.csv`

- `Latitude`
- `Longitude`
- `X Coordinate`
- `Y Coordinate`
- `Location`

`Latitude` and `Longitude` remain in the incident source as:

- they are the natural composite foreign key to `coordinate_source.csv`
- they already exist in the original dataset
- no generated key was needed

## Key Validation

The split was validated after generation.

- `ID` is unique in `crimes_original_reduced.csv`
- `IUCR` is unique in `offense_source.txt`
- `(Latitude, Longitude)` is unique in `coordinate_source.csv` for non-null pairs
- Missing `IUCR` foreign keys: `0`
- Missing non-null coordinate foreign keys: `0`
- Duplicate incident IDs found: `0`
- Inconsistent `IUCR` definitions found: `0`
- Inconsistent coordinate definitions found: `0`
- Surrogate keys added during source preparation: `0`

Validation report:

- `data/source_validation.txt`

## Logical Source Model

```mermaid
erDiagram
    CRIME_INCIDENT {
        bigint ID PK
        string CASE_NUMBER
        datetime DATE
        string BLOCK
        string LOCATION_DESCRIPTION
        boolean ARREST
        boolean DOMESTIC
        string BEAT
        string DISTRICT
        string WARD
        string COMMUNITY_AREA
        int YEAR
        datetime UPDATED_ON
        string LATITUDE FK
        string LONGITUDE FK
        string IUCR FK
    }

    OFFENSE_SOURCE {
        string IUCR PK
        string PRIMARY_TYPE
        string DESCRIPTION
        string FBI_CODE
    }

    COORDINATE_SOURCE {
        string LATITUDE PK
        string LONGITUDE PK
        string X_COORDINATE
        string Y_COORDINATE
        string LOCATION
    }

    OFFENSE_SOURCE ||--o{ CRIME_INCIDENT : classifies
    COORDINATE_SOURCE ||--o{ CRIME_INCIDENT : locates
```

## Assignment 

| Requirement | Status | Notes |
|---|---|---|
| OLTP dataset only | Satisfied | Incident-level operational records |
| Not AdventureWorks | Satisfied | Public-safety dataset |
| Around one year or more | Satisfied | More than three years in the local snapshot |
| Enough records and attributes | Satisfied | 759,161 rows, 22 original columns |
| Three raw data sources | Satisfied | Incident, offense, and coordinate sources created |
| At least two source types | Satisfied | CSV and text sources |
| Meaningful PK/FK relationships | Satisfied | `ID`, `IUCR`, and `(Latitude, Longitude)` validated without surrogate keys |
| Suitable for DW design, SSAS, reporting | Satisfied | Clear fact and dimension candidates |

## (Data warehouse)DW Use

Candidate warehouse structures:

- `FactIncident`
- `DimDate`
- `DimOffense`
- `DimLocation`
- `DimPoliceArea`

hierarchies:

- `Year -> Quarter -> Month -> Day`
- `District -> Beat`
- `Primary Type -> Description -> IUCR`
