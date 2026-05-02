with deduped as (
    select *,
        row_number() over (partition by _key order by _id desc) as _rn
    from {{ source('f1_streaming', 'overtakes') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['session_key', 'date', 'overtaking_driver_number', 'overtaken_driver_number']) }} as overtake_id,
    meeting_key,
    session_key,
    overtaking_driver_number,
    overtaken_driver_number,
    date as overtake_time,
    position as overtake_position
from deduped
where _rn = 1
