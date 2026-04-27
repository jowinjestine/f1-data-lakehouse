with qualifying as (
    select * from {{ ref('stg_jolpica_qualifying') }}
),

pole as (
    select year, round_number, q3_time as pole_time
    from qualifying
    where position = 1
)

select
    q.qualifying_id,
    q.year,
    q.round_number,
    q.driver_id,
    q.constructor_id,
    q.position,
    q.q1_time,
    q.q2_time,
    q.q3_time,
    p.pole_time,
    'jolpica' as data_source
from qualifying q
left join pole p
    on q.year = p.year
    and q.round_number = p.round_number
