"""
Export meta data for weather stations

The code is licensed under the MIT license.
"""

from io import BytesIO, StringIO
from gzip import GzipFile
import csv
import json
from routines import Routine

task = Routine('export.bulk.stations.meta', True)

def write_json_dump(data: list, name: str) -> None:

    global task

    file = BytesIO()

    if len(data) > 0:

        with GzipFile(fileobj=file, mode='w') as gz:
            gz.write(json.dumps(data, indent=4, default=str).encode())
            gz.close()
            file.seek(0)

        task.bulk_ftp.storbinary(f'STOR /stations/meta/{name}.json.gz', file)

# Export data for all weather stations
result = task.read(f'''
    SELECT
        `stations`.`id` AS `id`,
        `stations`.`name` AS `name`,
        `stations`.`name_alt` AS `name_alt`,
        `stations`.`country` AS `country`,
        `stations`.`region` AS `region`,
        `stations`.`national_id` AS `national_id`,
        CAST(`stations`.`wmo` AS CHAR(5)) AS `wmo`,
        `stations`.`icao` AS `icao`,
        `stations`.`iata` AS `iata`,
        `stations`.`latitude` AS `latitude`,
        `stations`.`longitude` AS `longitude`,
        `stations`.`altitude` AS `altitude`,
        `stations`.`tz` as `timezone`,
        `stations`.`history` as `history`,
        MIN(`inventory_hourly`.`start`) AS "hourly_start",
        MAX(`inventory_hourly`.`end`) AS "hourly_end",
        MIN(`inventory_daily`.`start`) AS "daily_start",
        MAX(`inventory_daily`.`end`) AS "daily_end",
        MIN(`inventory_monthly`.`start`) AS "monthly_start",
        MAX(`inventory_monthly`.`end`) AS "monthly_end",
        IF((SELECT `mode` FROM `inventory` WHERE `mode` = 'N' AND `inventory`.`station` = `stations`.`id`) IS NULL, NULL, 1) AS "normals_exist"
    FROM `stations`
    LEFT JOIN (
        SELECT
            `station`,
            `start`,
            `end`
        FROM `inventory`
        WHERE
            `mode` = "H"
    )
    AS
        `inventory_hourly`
    ON
        `stations`.`id` = `inventory_hourly`.`station`
    LEFT JOIN (
        SELECT
            `station`,
            `start`,
            `end`
        FROM `inventory`
        WHERE
            `mode` = "D"
    )
    AS
        `inventory_daily`
    ON
        `stations`.`id` = `inventory_daily`.`station`
    LEFT JOIN (
        SELECT
            `station`,
            `start`,
            `end`
        FROM `inventory`
        WHERE
            `mode` = "M"
    )
    AS
        `inventory_monthly`
    ON
        `stations`.`id` = `inventory_monthly`.`station`
    GROUP BY
        `stations`.`id`
''')

if result.rowcount > 0:

    # Fetch data
    data = result.fetchall()

    # Data lists
    full = []
    lite = []
    slim = []
    lib = []

    for record in data:

        # Create dict of names
        try:
            names = json.loads(data[2])
        except BaseException:
            names = {}
        names['en'] = record[1]

        # Create object
        object = {
            'id': record[0],
            'name': names,
            'country': record[3],
            'region': record[4],
            'identifiers': {
                'national': record[5],
                'wmo': record[6],
                'icao': record[7],
                'iata': record[8]
            },
            'location': {
                'latitude': record[9],
                'longitude': record[10],
                'elevation': record[11]
            },
            'timezone': record[12],
            'history': record[13],
            'inventory': {
                'hourly': {
                    'start': record[14],
                    'end': record[15]
                },
                'daily': {
                    'start': record[16],
                    'end': record[17]
                },
                'monthly': {
                    'start': record[18],
                    'end': record[19]
                },
                'normals': bool(record[20])
            }
        }

        # Add to full dump
        full.append(object)

        # Check if any data is available
        if record[15] is not None or record[17] is not None or record[19] is not None:
            lite.append(object)
            # Add slim rows
            record = record.values()
            slim_cols = [0, 1, 3, 4, 6, 7, 9, 10, 11, 12, 14, 15, 16, 17, 18, 19, 20]
            slim.append([record[i] for i in slim_cols])
            # Add lib rows
            record = record.values()
            lib_cols = [0, 1, 3, 4, 6, 7, 9, 10, 11, 12, 14, 15, 16, 17]
            lib.append([record[i] for i in lib_cols])

    # Write JSON dumps
    write_json_dump(full, 'full')
    write_json_dump(lite, 'lite')

    # Write slim dump
    if len(slim) > 0:

        file = BytesIO()

        with GzipFile(fileobj=file, mode='w') as gz:
            output = StringIO()
            writer = csv.writer(output, delimiter=',')
            writer.writerows(slim)
            gz.write(output.getvalue().encode())
            gz.close()
            file.seek(0)

        task.bulk_ftp.storbinary(f'STOR /stations/meta/slim.csv.gz', file)

    # Write lib dump
    if len(lib) > 0:

        file = BytesIO()

        with GzipFile(fileobj=file, mode='w') as gz:
            output = StringIO()
            writer = csv.writer(output, delimiter=',')
            writer.writerows(lib)
            gz.write(output.getvalue().encode())
            gz.close()
            file.seek(0)

        task.bulk_ftp.storbinary(f'STOR /stations/meta/lib.csv.gz', file)
