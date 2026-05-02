with deduped as (
    select *,
        row_number() over (partition by _key order by _id desc) as _rn
    from {{ source('f1_streaming', 'car_data') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['session_key', 'driver_number', 'date']) }} as telemetry_id,
    meeting_key,
    session_key,
    driver_number,
    date as recorded_at,
    rpm,
    speed as speed_kmh,
    n_gear as gear,
    throttle as throttle_pct,
    brake as brake_pct,
    drs as drs_status
from deduped
where _rn = 1
