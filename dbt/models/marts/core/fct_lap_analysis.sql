with laps as (
    select
        l.*,
        s.session_type,
        s.season_year as year,
        s.circuit_short_name
    from {{ ref('stg_openf1_laps') }} l
    inner join {{ ref('stg_openf1_sessions') }} s
        on l.session_key = s.session_key
),

stint_info as (
    select session_key, driver_number, lap_start, lap_end,
           tyre_compound, tyre_age_at_start, stint_number
    from {{ ref('stg_openf1_stints') }}
),

session_weather as (
    select
        session_key,
        avg(air_temp_celsius) as avg_air_temp,
        avg(track_temp_celsius) as avg_track_temp,
        avg(humidity_pct) as avg_humidity,
        max(case when is_raining then 1 else 0 end) = 1 as had_rain,
        avg(wind_speed_ms) as avg_wind_speed
    from {{ ref('stg_openf1_weather') }}
    group by session_key
),

drivers as (
    select session_key, driver_number, full_name, name_acronym
    from {{ ref('stg_openf1_drivers') }}
)

select
    laps.lap_id,
    laps.year,
    laps.session_key,
    laps.session_type,
    laps.circuit_short_name,
    laps.driver_number,
    d.full_name as driver_name,
    d.name_acronym as driver_code,
    laps.lap_number,
    laps.lap_time_seconds,
    laps.sector1_seconds,
    laps.sector2_seconds,
    laps.sector3_seconds,
    laps.speed_trap_i1,
    laps.speed_trap_i2,
    laps.speed_trap_st,
    laps.is_pit_out_lap,
    si.tyre_compound,
    si.stint_number,
    laps.lap_number - si.lap_start + coalesce(si.tyre_age_at_start, 0) as tyre_age,
    sw.avg_air_temp,
    sw.avg_track_temp,
    sw.avg_humidity,
    sw.had_rain,
    sw.avg_wind_speed
from laps
left join stint_info si
    on laps.session_key = si.session_key
    and laps.driver_number = si.driver_number
    and laps.lap_number between si.lap_start and si.lap_end
left join session_weather sw on laps.session_key = sw.session_key
left join drivers d
    on laps.session_key = d.session_key
    and laps.driver_number = d.driver_number
