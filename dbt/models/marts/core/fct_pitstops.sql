with sessions as (
    select session_key, season_year as year, meeting_key, circuit_short_name
    from {{ ref('stg_openf1_sessions') }}
),

drivers as (
    select session_key, driver_number, full_name, name_acronym
    from {{ ref('stg_openf1_drivers') }}
)

select
    p.pit_stop_id,
    s.year,
    s.meeting_key,
    p.session_key,
    s.circuit_short_name,
    p.driver_number,
    d.full_name as driver_name,
    d.name_acronym as driver_code,
    p.lap_number,
    p.pit_time,
    p.pit_lane_seconds,
    p.pit_stop_seconds,
    p.pit_total_seconds
from {{ ref('stg_openf1_pit') }} p
inner join sessions s on p.session_key = s.session_key
left join drivers d
    on p.session_key = d.session_key
    and p.driver_number = d.driver_number
