with latest_session_per_driver as (
    select
        driver_number,
        full_name,
        first_name,
        last_name,
        broadcast_name,
        name_acronym,
        team_name,
        team_colour,
        headshot_url,
        country_code,
        row_number() over (
            partition by driver_number
            order by session_key desc
        ) as rn
    from {{ ref('stg_openf1_drivers') }}
    where driver_number is not null
)

select
    driver_number as driver_key,
    driver_number,
    full_name,
    first_name,
    last_name,
    broadcast_name,
    name_acronym as driver_code,
    team_name as current_team,
    team_colour as current_team_colour,
    headshot_url,
    country_code
from latest_session_per_driver
where rn = 1
