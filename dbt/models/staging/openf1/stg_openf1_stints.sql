with deduped as (
    select *,
        row_number() over (partition by _key order by _id desc) as _rn
    from {{ source('f1_streaming', 'stints') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['session_key', 'driver_number', 'stint_number']) }} as stint_id,
    meeting_key,
    session_key,
    driver_number,
    stint_number,
    lap_start,
    lap_end,
    lap_end - lap_start + 1 as stint_laps,
    compound as tyre_compound,
    tyre_age_at_start
from deduped
where _rn = 1
