with deduped as (
    select *,
        row_number() over (partition by _key order by _id desc) as _rn
    from {{ source('f1_streaming', 'intervals') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['session_key', 'driver_number', 'date']) }} as interval_id,
    meeting_key,
    session_key,
    driver_number,
    date as recorded_at,
    gap_to_leader as gap_to_leader_raw,
    safe_cast(gap_to_leader as float64) as gap_to_leader_seconds,
    interval as interval_raw,
    safe_cast(interval as float64) as interval_seconds
from deduped
where _rn = 1
