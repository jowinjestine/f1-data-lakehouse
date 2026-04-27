select *
from {{ ref('stg_laps') }}
where lap_time_seconds <= 0
