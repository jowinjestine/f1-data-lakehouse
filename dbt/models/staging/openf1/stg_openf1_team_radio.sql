with deduped as (
    select *,
        row_number() over (partition by _key order by _id desc) as _rn
    from {{ source('f1_streaming', 'team_radio') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['session_key', 'driver_number', 'date']) }} as radio_id,
    meeting_key,
    session_key,
    driver_number,
    date as broadcast_time,
    recording_url
from deduped
where _rn = 1
