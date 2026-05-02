with qualifying_sessions as (
    select session_key, meeting_key, season_year as year, circuit_short_name, session_type
    from {{ ref('stg_openf1_sessions') }}
    where lower(session_type) in ('qualifying', 'sprint qualifying', 'sprint shootout')
),

best_laps as (
    select
        l.session_key,
        l.driver_number,
        min(l.lap_time_seconds) as best_lap_seconds,
        count(*) as laps_driven
    from {{ ref('stg_openf1_laps') }} l
    inner join qualifying_sessions qs on l.session_key = qs.session_key
    where l.lap_time_seconds is not null
    group by l.session_key, l.driver_number
),

final_positions as (
    select
        session_key,
        driver_number,
        race_position as qualifying_position,
        row_number() over (
            partition by session_key, driver_number
            order by recorded_at desc
        ) as rn
    from {{ ref('stg_openf1_position') }}
),

drivers as (
    select session_key, driver_number, full_name, name_acronym, team_name
    from {{ ref('stg_openf1_drivers') }}
),

pole_times as (
    select bl.session_key, bl.best_lap_seconds as pole_time
    from best_laps bl
    inner join final_positions fp
        on bl.session_key = fp.session_key
        and bl.driver_number = fp.driver_number
        and fp.rn = 1
        and fp.qualifying_position = 1
)

select
    {{ dbt_utils.generate_surrogate_key(['qs.session_key', 'bl.driver_number']) }} as qualifying_id,
    qs.year,
    qs.meeting_key,
    qs.session_key,
    qs.session_type,
    qs.circuit_short_name,
    bl.driver_number,
    d.full_name as driver_name,
    d.name_acronym as driver_code,
    d.team_name,
    fp.qualifying_position,
    bl.best_lap_seconds,
    bl.laps_driven,
    pt.pole_time,
    bl.best_lap_seconds - pt.pole_time as gap_to_pole_seconds
from best_laps bl
inner join qualifying_sessions qs on bl.session_key = qs.session_key
left join final_positions fp
    on bl.session_key = fp.session_key
    and bl.driver_number = fp.driver_number
    and fp.rn = 1
left join drivers d
    on bl.session_key = d.session_key
    and bl.driver_number = d.driver_number
left join pole_times pt on bl.session_key = pt.session_key
