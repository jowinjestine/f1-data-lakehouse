with circuits as (
    select
        s.circuit_key,
        s.circuit_short_name,
        s.country_code,
        s.country_name,
        s.location as city,
        m.circuit_type,
        row_number() over (
            partition by s.circuit_key
            order by s.session_key desc
        ) as rn
    from {{ ref('stg_openf1_sessions') }} s
    left join {{ ref('stg_openf1_meetings') }} m
        on s.meeting_key = m.meeting_key
    where s.circuit_key is not null
)

select
    circuit_key,
    circuit_short_name as circuit_name,
    city,
    country_code,
    country_name,
    circuit_type
from circuits
where rn = 1
