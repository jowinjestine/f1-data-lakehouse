select
    circuitId as circuit_id,
    circuitName as circuit_name,
    locality as city,
    country,
    cast(lat as float64) as latitude,
    cast(lng as float64) as longitude,
    ingestion_timestamp
from {{ source('f1_raw', 'jolpica_circuits') }}
