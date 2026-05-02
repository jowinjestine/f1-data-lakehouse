select
    team_key as constructor_key,
    team_name as constructor_name,
    team_colour
from {{ ref('dim_teams') }}
