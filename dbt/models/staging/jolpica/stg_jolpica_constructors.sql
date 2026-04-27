select
    constructorId as constructor_id,
    name as constructor_name,
    nationality,
    ingestion_timestamp
from {{ source('f1_raw', 'jolpica_constructors') }}
