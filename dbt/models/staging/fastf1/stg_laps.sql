with raw as (
    select * from {{ source('f1_raw', 'fastf1_laps') }}
),

latest_objects as (
    select * from {{ source('f1_ops', 'latest_successful_objects') }}
    where source = 'fastf1' and dataset = 'laps'
),

filtered as (
    select r.*
    from raw r
    inner join latest_objects lo
        on r.year = lo.year
        and r.round = lo.round
        and r.session = lo.session_type
        and r.ingest_run_id = lo.latest_ingest_run_id
)

select
    {{ dbt_utils.generate_surrogate_key(['year', 'round', 'session', 'driver_number', 'lap_number']) }} as lap_id,
    cast(year as int64) as year,
    cast(round as int64) as round_number,
    session as session_type,
    cast(driver_number as string) as driver_number,
    cast(lap_number as int64) as lap_number,
    cast(lap_time as float64) as lap_time_seconds,
    cast(sector1_time as float64) as sector1_seconds,
    cast(sector2_time as float64) as sector2_seconds,
    cast(sector3_time as float64) as sector3_seconds,
    compound as tyre_compound,
    cast(tyre_life as float64) as tyre_life,
    cast(is_accurate as bool) as is_accurate,
    ingestion_timestamp,
    schema_version
from filtered
where is_accurate = true
