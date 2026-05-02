with deduped as (
    select *,
        row_number() over (partition by _key order by _id desc) as _rn
    from {{ source('f1_streaming', 'sessions') }}
)

select
    session_key,
    meeting_key,
    session_type,
    session_name,
    date_start as session_start,
    date_end as session_end,
    timestamp_diff(date_end, date_start, MINUTE) as session_duration_minutes,
    circuit_key,
    circuit_short_name,
    country_key,
    country_code,
    country_name,
    location,
    gmt_offset,
    year as season_year,
    is_cancelled
from deduped
where _rn = 1
