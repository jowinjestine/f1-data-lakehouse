with raw as (
    select * from {{ source('f1_raw', 'fastf1_results') }}
),

latest_objects as (
    select * from {{ source('f1_ops', 'latest_successful_objects') }}
    where source = 'fastf1' and dataset = 'results'
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
    {{ dbt_utils.generate_surrogate_key(['year', 'round', 'session', 'driver_number']) }} as result_id,
    cast(year as int64) as year,
    cast(round as int64) as round_number,
    session as session_type,
    cast(driver_number as string) as driver_number,
    abbreviation as driver_abbreviation,
    cast(position as float64) as position,
    cast(points as float64) as points,
    status,
    case
        when status in ('Finished', '+1 Lap', '+2 Laps', '+3 Laps') then 'finished'
        when status = 'DNS' then 'dns'
        else 'dnf'
    end as finish_status,
    ingestion_timestamp,
    schema_version
from filtered
