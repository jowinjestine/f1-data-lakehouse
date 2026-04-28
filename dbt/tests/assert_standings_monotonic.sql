with season_points as (
    select
        year,
        driver_key,
        total_points
    from {{ ref('agg_season_standings') }}
    where total_points < 0
)

select * from season_points
