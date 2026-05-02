with deduped as (
    select *,
        row_number() over (partition by _key order by _id desc) as _rn
    from {{ source('f1_streaming', 'pit') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['session_key', 'driver_number', 'lap_number']) }} as pit_stop_id,
    meeting_key,
    session_key,
    driver_number,
    lap_number,
    date as pit_time,
    lane_duration as pit_lane_seconds,
    stop_duration as pit_stop_seconds,
    pit_duration as pit_total_seconds
from deduped
where _rn = 1
