with race_sessions as (
    select session_key, meeting_key, season_year, circuit_short_name
    from {{ ref('stg_openf1_sessions') }}
    where lower(session_type) = 'race'
      and not is_cancelled
),

final_positions as (
    select
        session_key,
        driver_number,
        race_position as finish_position,
        row_number() over (
            partition by session_key, driver_number
            order by recorded_at desc
        ) as rn
    from {{ ref('stg_openf1_position') }}
),

laps_completed as (
    select
        session_key,
        driver_number,
        max(lap_number) as total_laps,
        sum(lap_time_seconds) as total_race_time_seconds
    from {{ ref('stg_openf1_laps') }}
    group by session_key, driver_number
),

points_gained as (
    select
        session_key,
        driver_number,
        points_current - coalesce(points_start, 0) as session_points
    from {{ ref('stg_openf1_championship_drivers') }}
),

drivers as (
    select session_key, driver_number, full_name, name_acronym, team_name
    from {{ ref('stg_openf1_drivers') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['rs.session_key', 'fp.driver_number']) }} as result_id,
    rs.season_year as year,
    rs.meeting_key,
    rs.session_key,
    rs.circuit_short_name,
    fp.driver_number,
    d.full_name as driver_name,
    d.name_acronym as driver_code,
    d.team_name,
    fp.finish_position,
    coalesce(pg.session_points, 0) as points,
    lc.total_laps as laps_completed,
    lc.total_race_time_seconds,
    fp.finish_position = 1 as is_winner,
    fp.finish_position <= 3 as is_podium
from race_sessions rs
inner join final_positions fp
    on rs.session_key = fp.session_key
    and fp.rn = 1
left join laps_completed lc
    on rs.session_key = lc.session_key
    and fp.driver_number = lc.driver_number
left join points_gained pg
    on rs.session_key = pg.session_key
    and fp.driver_number = pg.driver_number
left join drivers d
    on rs.session_key = d.session_key
    and fp.driver_number = d.driver_number
