with raw as (
    select * from {{ source('f1_raw', 'jolpica_pitstops') }}
),

latest_objects as (
    select * from {{ source('f1_ops', 'latest_successful_objects') }}
    where source = 'jolpica' and dataset = 'pitstops'
),

filtered as (
    select r.*
    from raw r
    inner join latest_objects lo
        on r.year = lo.year
        and r.round = lo.round
        and r.ingest_run_id = lo.latest_ingest_run_id
)

select
    {{ dbt_utils.generate_surrogate_key(['year', 'round', 'driverId', 'stop']) }} as pitstop_id,
    cast(year as int64) as year,
    cast(round as int64) as round_number,
    driverId as driver_id,
    cast(stop as int64) as stop_number,
    cast(lap as int64) as lap,
    duration as duration_string,
    ingestion_timestamp
from filtered
