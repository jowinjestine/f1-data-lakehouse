select l.*
from {{ ref('stg_laps') }} l
left join {{ ref('stg_results') }} r
    on l.year = r.year
    and l.round_number = r.round_number
    and l.session_type = r.session_type
    and l.driver_number = r.driver_number
where r.result_id is null
