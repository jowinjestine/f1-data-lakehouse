with latest_per_team as (
    select
        team_name,
        team_colour,
        row_number() over (
            partition by team_name
            order by session_key desc
        ) as rn
    from {{ ref('stg_openf1_drivers') }}
    where team_name is not null
)

select
    {{ dbt_utils.generate_surrogate_key(['team_name']) }} as team_key,
    team_name,
    team_colour
from latest_per_team
where rn = 1
