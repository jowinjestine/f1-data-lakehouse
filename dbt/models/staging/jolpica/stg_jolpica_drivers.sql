select
    driverId as driver_id,
    givenName as first_name,
    familyName as last_name,
    concat(givenName, ' ', familyName) as full_name,
    dateOfBirth as date_of_birth,
    driverNationality as nationality,
    driverCode as driver_code,
    driverNumber as permanent_number,
    ingestion_timestamp
from {{ source('f1_raw', 'jolpica_drivers') }}
