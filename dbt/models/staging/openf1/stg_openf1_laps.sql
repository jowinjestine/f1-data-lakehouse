with deduped as (
    select *,
        row_number() over (partition by _key order by _id desc) as _rn
    from {{ source('f1_streaming', 'laps') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['session_key', 'driver_number', 'lap_number']) }} as lap_id,
    meeting_key,
    session_key,
    driver_number,
    lap_number,
    date_start as lap_start_time,
    duration_sector_1 as sector1_seconds,
    duration_sector_2 as sector2_seconds,
    duration_sector_3 as sector3_seconds,
    i1_speed as speed_trap_i1,
    i2_speed as speed_trap_i2,
    st_speed as speed_trap_st,
    is_pit_out_lap,
    lap_duration as lap_time_seconds,
    segments_sector_1,
    segments_sector_2,
    segments_sector_3
from deduped
where _rn = 1
