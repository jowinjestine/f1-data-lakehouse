with deduped as (
    select *,
        row_number() over (partition by _key order by _id desc) as _rn
    from {{ source('f1_streaming', 'race_control') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['session_key', 'date', 'driver_number', 'category', 'message']) }} as race_control_id,
    meeting_key,
    session_key,
    date as event_time,
    driver_number,
    lap_number,
    category,
    flag,
    scope,
    sector,
    qualifying_phase,
    message
from deduped
where _rn = 1
