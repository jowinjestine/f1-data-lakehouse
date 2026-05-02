with deduped as (
    select *,
        row_number() over (partition by _key order by _id desc) as _rn
    from {{ source('f1_streaming', 'location') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['session_key', 'driver_number', 'date']) }} as location_id,
    meeting_key,
    session_key,
    driver_number,
    date as recorded_at,
    x as pos_x,
    y as pos_y,
    z as pos_z
from deduped
where _rn = 1
