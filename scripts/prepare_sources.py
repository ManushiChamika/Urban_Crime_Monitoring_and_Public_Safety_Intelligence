import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data"
RAW_FILE = DATA_DIR / "Crimes_-_2001_to_Present_20260321.csv"

INCIDENT_FILE = DATA_DIR / "crimes_original_reduced.csv"
COORDINATE_FILE = DATA_DIR / "coordinate_source.csv"
OFFENSE_FILE = DATA_DIR / "offense_source.txt"
VALIDATION_FILE = DATA_DIR / "source_validation.txt"

COORDINATE_FIELDS = [
    "Latitude",
    "Longitude",
    "X Coordinate",
    "Y Coordinate",
    "Location",
]

INCIDENT_FIELDS = [
    "ID",
    "Case Number",
    "Date",
    "Block",
    "Location Description",
    "Arrest",
    "Domestic",
    "Beat",
    "District",
    "Ward",
    "Community Area",
    "Year",
    "Updated On",
    "Latitude",
    "Longitude",
    "IUCR",
]

OFFENSE_FIELDS = [
    "IUCR",
    "Primary Type",
    "Description",
    "FBI Code",
]

def prepare_sources():
    if not RAW_FILE.exists():
        raise FileNotFoundError(f"Raw file not found: {RAW_FILE}")

    DATA_DIR.mkdir(parents=True, exist_ok=True)

    coordinate_lookup = {}
    offense_lookup = {}
    seen_ids = set()

    row_count = 0
    duplicate_ids = 0
    inconsistent_iucr = 0
    inconsistent_coordinates = 0
    blank_coordinate_rows = 0

    for path in [INCIDENT_FILE, COORDINATE_FILE, OFFENSE_FILE, VALIDATION_FILE]:
        if path.exists():
            path.unlink()

    with (
        RAW_FILE.open("r", encoding="utf-8-sig", newline="") as raw_handle,
        INCIDENT_FILE.open("w", encoding="utf-8", newline="") as incident_handle,
        COORDINATE_FILE.open("w", encoding="utf-8", newline="") as coordinate_handle,
    ):
        reader = csv.DictReader(raw_handle)
        incident_writer = csv.DictWriter(incident_handle, fieldnames=INCIDENT_FIELDS)
        coordinate_writer = csv.DictWriter(coordinate_handle, fieldnames=COORDINATE_FIELDS)

        incident_writer.writeheader()
        coordinate_writer.writeheader()

        for row in reader:
            row_count += 1

            incident_id = row["ID"]
            if incident_id in seen_ids:
                duplicate_ids += 1
                continue
            seen_ids.add(incident_id)

            offense_row = tuple(row[field] for field in OFFENSE_FIELDS[1:])
            current_offense = offense_lookup.get(row["IUCR"])
            if current_offense is None:
                offense_lookup[row["IUCR"]] = offense_row
            elif current_offense != offense_row:
                inconsistent_iucr += 1
                raise ValueError(
                    f"Inconsistent IUCR mapping for {row['IUCR']}: "
                    f"{current_offense} vs {offense_row}"
                )

            latitude = row["Latitude"]
            longitude = row["Longitude"]
            if latitude and longitude:
                coordinate_key = (latitude, longitude)
                coordinate_row = tuple(row[field] for field in COORDINATE_FIELDS[2:])
                current_coordinate = coordinate_lookup.get(coordinate_key)
                if current_coordinate is None:
                    coordinate_lookup[coordinate_key] = coordinate_row
                    coordinate_writer.writerow(
                        {field: row[field] for field in COORDINATE_FIELDS}
                    )
                elif current_coordinate != coordinate_row:
                    inconsistent_coordinates += 1
                    raise ValueError(
                        f"Inconsistent coordinate mapping for {coordinate_key}: "
                        f"{current_coordinate} vs {coordinate_row}"
                    )
            else:
                blank_coordinate_rows += 1

            incident_writer.writerow(
                {field: row[field] for field in INCIDENT_FIELDS}
            )

    with OFFENSE_FILE.open("w", encoding="utf-8", newline="") as offense_handle:
        writer = csv.writer(offense_handle, delimiter="\t")
        writer.writerow(OFFENSE_FIELDS)
        for iucr in sorted(offense_lookup):
            writer.writerow([iucr, *offense_lookup[iucr]])

    with INCIDENT_FILE.open("r", encoding="utf-8", newline="") as incident_handle:
        incident_count = sum(1 for _ in incident_handle) - 1

    with COORDINATE_FILE.open("r", encoding="utf-8", newline="") as coordinate_handle:
        coordinate_count = sum(1 for _ in coordinate_handle) - 1

    offense_count = len(offense_lookup)
    missing_iucr_fk = 0
    missing_non_null_coordinate_fk = 0

    with VALIDATION_FILE.open("w", encoding="utf-8", newline="") as validation_handle:
        validation_handle.write("Prepared source validation\n")
        validation_handle.write(f"Raw rows processed: {row_count}\n")
        validation_handle.write(f"Incident rows written: {incident_count}\n")
        validation_handle.write(f"Offense rows written: {offense_count}\n")
        validation_handle.write(f"Coordinate rows written: {coordinate_count}\n")
        validation_handle.write(f"Duplicate incident IDs found: {duplicate_ids}\n")
        validation_handle.write(f"Inconsistent IUCR definitions found: {inconsistent_iucr}\n")
        validation_handle.write(f"Inconsistent coordinate definitions found: {inconsistent_coordinates}\n")
        validation_handle.write(f"Missing IUCR foreign keys: {missing_iucr_fk}\n")
        validation_handle.write(f"Missing non-null coordinate foreign keys: {missing_non_null_coordinate_fk}\n")
        validation_handle.write(f"Incident rows with blank Latitude/Longitude: {blank_coordinate_rows}\n")
        validation_handle.write("Surrogate keys added during source preparation: 0\n")
        validation_handle.write("Primary key checks:\n")
        validation_handle.write("- crimes_original_reduced.csv: ID is unique\n")
        validation_handle.write("- offense_source.txt: IUCR is unique\n")
        validation_handle.write("- coordinate_source.csv: (Latitude, Longitude) is unique for non-null pairs\n")
        validation_handle.write("Foreign key checks:\n")
        validation_handle.write("- crimes_original_reduced.csv.IUCR -> offense_source.txt.IUCR valid for all rows\n")
        validation_handle.write("- crimes_original_reduced.csv.(Latitude, Longitude) -> coordinate_source.csv.(Latitude, Longitude) valid for all non-null pairs\n")


if __name__ == "__main__":
    prepare_sources()
