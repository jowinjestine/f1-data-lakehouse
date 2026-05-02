with results as (
    select * from {{ ref('fct_race_results') }}
    where team_name is not null
      and finish_position is not null
),

teammates as (
    select
        r1.year,
        r1.session_key,
        r1.team_name,
        r1.driver_number as driver_1_number,
        r1.driver_name as driver_1_name,
        r2.driver_number as driver_2_number,
        r2.driver_name as driver_2_name,
        case when r1.finish_position < r2.finish_position then 1 else 0 end as driver_1_ahead
    from results r1
    inner join results r2
        on r1.session_key = r2.session_key
        and r1.team_name = r2.team_name
        and r1.driver_number < r2.driver_number
)

select
    year,
    team_name,
    driver_1_number,
    driver_1_name,
    driver_2_number,
    driver_2_name,
    count(*) as races_together,
    sum(driver_1_ahead) as driver_1_ahead_count,
    count(*) - sum(driver_1_ahead) as driver_2_ahead_count
from teammates
group by year, team_name, driver_1_number, driver_1_name, driver_2_number, driver_2_name
