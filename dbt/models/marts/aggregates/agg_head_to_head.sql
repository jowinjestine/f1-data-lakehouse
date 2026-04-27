with results as (
    select * from {{ ref('fct_race_results') }}
    where constructor_key is not null
),

teammates as (
    select
        r1.year,
        r1.round_number,
        r1.constructor_key,
        r1.driver_key as driver_1_key,
        r1.driver_name as driver_1_name,
        r2.driver_key as driver_2_key,
        r2.driver_name as driver_2_name,
        case when r1.position < r2.position then 1 else 0 end as driver_1_ahead
    from results r1
    inner join results r2
        on r1.year = r2.year
        and r1.round_number = r2.round_number
        and r1.constructor_key = r2.constructor_key
        and r1.driver_key < r2.driver_key
    where r1.position is not null and r2.position is not null
)

select
    year,
    constructor_key,
    driver_1_key,
    driver_1_name,
    driver_2_key,
    driver_2_name,
    count(*) as races_together,
    sum(driver_1_ahead) as driver_1_ahead_count,
    count(*) - sum(driver_1_ahead) as driver_2_ahead_count
from teammates
group by year, constructor_key, driver_1_key, driver_1_name, driver_2_key, driver_2_name
