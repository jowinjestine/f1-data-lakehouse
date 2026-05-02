with results as (
    select * from {{ ref('fct_race_results') }}
),

qualifying as (
    select
        driver_number,
        countif(qualifying_position = 1) as total_poles
    from {{ ref('fct_qualifying') }}
    where session_type = 'Qualifying'
    group by driver_number
)

select
    r.driver_number,
    r.driver_name,
    min(r.year) as first_year,
    max(r.year) as last_year,
    count(*) as total_starts,
    sum(r.points) as total_points,
    countif(r.is_winner) as total_wins,
    countif(r.is_podium) as total_podiums,
    coalesce(q.total_poles, 0) as total_poles,
    countif(r.is_winner) / nullif(count(*), 0) as win_rate,
    countif(r.is_podium) / nullif(count(*), 0) as podium_rate,
    avg(r.finish_position) as avg_finish_position,
    count(distinct r.year) as seasons
from results r
left join qualifying q on r.driver_number = q.driver_number
where r.finish_position is not null
group by r.driver_number, r.driver_name, q.total_poles
