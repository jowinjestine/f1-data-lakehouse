with jolpica as (
    select
        result_id,
        year,
        round_number,
        driver_id,
        cast(null as string) as driver_abbreviation,
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
        driver_abbreviation,
        cast(null as string) as constructor_id,
        cast(position as int64) as position,
        points,
        status,
        cast(null as int64) as grid_position,
        cast(null as int64) as laps_completed,
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
        coalesce(dd_jolpica.driver_key, dd_fastf1.driver_key) as driver_key,
        coalesce(dd_jolpica.full_name, dd_fastf1.full_name) as driver_name,
        dc.constructor_key,
        dc.constructor_name
    from combined c
    left join {{ ref('dim_drivers') }} dd_jolpica
        on c.data_source = 'jolpica'
        and c.driver_id = dd_jolpica.jolpica_driver_id
    left join {{ ref('dim_drivers') }} dd_fastf1
        on c.data_source = 'fastf1'
        and c.driver_abbreviation = dd_fastf1.driver_code
    left join {{ ref('dim_constructors') }} dc
        on c.constructor_id = dc.jolpica_constructor_id
)

select * from with_dims
