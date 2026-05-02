select
    constructorId as constructor_id,
    constructorName as constructor_name,
    constructorNationality as nationality,
    ingestion_timestamp
from {{ source('f1_raw', 'jolpica_constructors') }}
