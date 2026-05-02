with deduped as (
    select *,
        row_number() over (partition by _key order by _id desc) as _rn
    from {{ source('f1_streaming', 'meetings') }}
)

select
    meeting_key,
    meeting_name,
    meeting_official_name,
    location,
    country_key,
    country_code,
    country_name,
    circuit_key,
    circuit_short_name,
    circuit_type,
    gmt_offset,
    date_start as meeting_start,
    date_end as meeting_end,
    year as season_year,
    is_cancelled
from deduped
where _rn = 1
