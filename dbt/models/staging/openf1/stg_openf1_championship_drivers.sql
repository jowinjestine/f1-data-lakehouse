with deduped as (
    select *,
        row_number() over (partition by _key order by _id desc) as _rn
    from {{ source('f1_streaming', 'championship_drivers') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['session_key', 'driver_number']) }} as championship_driver_id,
    meeting_key,
    session_key,
    driver_number,
    position_start,
    position_current,
    points_start,
    points_current,
    points_current - points_start as points_gained
from deduped
where _rn = 1
