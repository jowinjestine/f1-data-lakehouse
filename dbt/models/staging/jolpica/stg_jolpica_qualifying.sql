with raw as (
    select * from {{ source('f1_raw', 'jolpica_qualifying') }}
),

latest_objects as (
    select * from {{ source('f1_ops', 'latest_successful_objects') }}
    where source = 'jolpica' and dataset = 'qualifying'
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
    {{ dbt_utils.generate_surrogate_key(['year', 'round', 'driverId']) }} as qualifying_id,
    cast(year as int64) as year,
    cast(round as int64) as round_number,
    driverId as driver_id,
    constructorId as constructor_id,
    cast(position as int64) as position,
    Q1 as q1_time,
    Q2 as q2_time,
    Q3 as q3_time,
    ingestion_timestamp
from filtered
