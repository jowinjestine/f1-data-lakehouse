with deduped as (
    select *,
        row_number() over (partition by _key order by _id desc) as _rn
    from {{ source('f1_streaming', 'weather') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['session_key', 'date']) }} as weather_id,
    meeting_key,
    session_key,
    date as recorded_at,
    air_temperature as air_temp_celsius,
    track_temperature as track_temp_celsius,
    humidity as humidity_pct,
    pressure as pressure_mbar,
    rainfall > 0 as is_raining,
    rainfall,
    wind_speed as wind_speed_ms,
    wind_direction as wind_direction_deg,
    case
        when wind_direction >= 337.5 or wind_direction < 22.5 then 'N'
        when wind_direction >= 22.5 and wind_direction < 67.5 then 'NE'
        when wind_direction >= 67.5 and wind_direction < 112.5 then 'E'
        when wind_direction >= 112.5 and wind_direction < 157.5 then 'SE'
        when wind_direction >= 157.5 and wind_direction < 202.5 then 'S'
        when wind_direction >= 202.5 and wind_direction < 247.5 then 'SW'
        when wind_direction >= 247.5 and wind_direction < 292.5 then 'W'
        when wind_direction >= 292.5 and wind_direction < 337.5 then 'NW'
    end as wind_cardinal
from deduped
where _rn = 1
