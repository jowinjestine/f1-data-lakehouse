with deduped as (
    select *,
        row_number() over (partition by _key order by _id desc) as _rn
    from {{ source('f1_streaming', 'position') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['session_key', 'driver_number', 'date']) }} as position_id,
    meeting_key,
    session_key,
    driver_number,
    date as recorded_at,
    position as race_position
from deduped
where _rn = 1
