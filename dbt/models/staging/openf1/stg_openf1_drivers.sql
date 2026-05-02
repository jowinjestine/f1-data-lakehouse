with deduped as (
    select *,
        row_number() over (partition by _key order by _id desc) as _rn
    from {{ source('f1_streaming', 'drivers') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['session_key', 'driver_number']) }} as driver_session_id,
    meeting_key,
    session_key,
    driver_number,
    broadcast_name,
    full_name,
    first_name,
    last_name,
    name_acronym,
    team_name,
    team_colour,
    headshot_url,
    country_code
from deduped
where _rn = 1
