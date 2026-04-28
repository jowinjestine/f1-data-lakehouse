with jolpica as (
    select
        result_id,
        year,
        round_number,
        driver_id,
        constructor_id,
        position,
        points,
        status,
        grid_position,
        laps_completed,
        'jolpica' as data_source
    from {{ ref('stg_jolpica_results') }}
    where year < 2018
),

fastf1 as (
    select
        result_id,
        year,
        round_number,
        driver_number as driver_id,
        null as constructor_id,
        cast(position as int64) as position,
        points,
        status,
        null as grid_position,
        null as laps_completed,
        'fastf1' as data_source
    from {{ ref('stg_results') }}
    where session_type = 'R'
),

combined as (
    select * from jolpica
    union all
    select * from fastf1
),

with_dims as (
    select
        c.*,
        dd.driver_key,
        dd.full_name as driver_name,
        dc.constructor_key,
        dc.constructor_name
    from combined c
    left join {{ ref('dim_drivers') }} dd
        on c.driver_id = dd.jolpica_driver_id
    left join {{ ref('dim_constructors') }} dc
        on c.constructor_id = dc.jolpica_constructor_id
)

select * from with_dims
